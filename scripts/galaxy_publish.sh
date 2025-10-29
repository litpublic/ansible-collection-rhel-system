#!/usr/bin/env bash

set -euo pipefail

SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CI_PROJECT_DIR="${CI_PROJECT_DIR:-$(cd "$SCRIPT_PATH/.." && pwd)}"
ARTIFACT_DIR="${ARTIFACT_DIR:-dist}"
PYTHON_BIN="${PYTHON_BIN:-python3}"
GALAXY_SERVER="${GALAXY_SERVER:-https://galaxy.ansible.com}"
ANSIBLE_CORE_VERSION="${ANSIBLE_CORE_VERSION:-2.16.9}"
DRY_RUN=false
COMMAND=""
SERVER_OVERRIDE=""

log()  { printf '\033[1;36m==> %s\033[0m\n' "$1"; }
warn() { printf '\033[1;33mWARN:\033[0m %s\n' "$1" >&2; }
die()  { printf '\033[1;31mERROR:\033[0m %s\n' "$1" >&2; exit "${2:-1}"; }

usage() {
  cat <<'USAGE'
Usage:
  galaxy_publish.sh <command> [--dry-run] [--server URL]

Commands:
  build        Build the Ansible collection artifact
  publish      Publish the artifact to Galaxy (requires GALAXY_TOKEN unless --dry-run)
  all          Run build then publish (publish honours --dry-run)
  list         List artifacts in dist/
  verify       Build then install artifact into a temporary collections path
  help         Print this message

Environment:
  COLLECTION_NAMESPACE (required)
  COLLECTION_NAME      (required)
  GALAXY_TOKEN         (publish only)
  GALAXY_SERVER        (default https://galaxy.ansible.com)
  PYTHON_BIN           (default python3)
  ARTIFACT_DIR         (default dist)
  CI_PROJECT_DIR       (default parent of this script)
  SOURCE_DATE_EPOCH    (optional for reproducible archives)
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    build|publish|all|list|verify|help)
      COMMAND="$1"
      shift
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --server)
      [[ $# -ge 2 ]] || die "--server requires a URL argument"
      SERVER_OVERRIDE="$2"
      shift 2
      ;;
    *)
      die "Unknown argument '$1'"
      ;;
  esac
  [[ "$COMMAND" == "help" ]] && break
done

[[ -z "$COMMAND" ]] && die "No command specified. Use 'help'." 2
[[ "$COMMAND" == "help" ]] && { usage; exit 0; }

[[ -n "$SERVER_OVERRIDE" ]] && GALAXY_SERVER="$SERVER_OVERRIDE"

need_env() {
  local name="$1"
  local value="${!name:-}"
  [[ -z "$value" ]] && die "Environment variable '$name' must be set."
}

need_env COLLECTION_NAMESPACE
need_env COLLECTION_NAME

if [[ "$COMMAND" == "publish" || "$COMMAND" == "all" ]]; then
  [[ "$DRY_RUN" == true ]] || need_env GALAXY_TOKEN
fi

COLLECTION_DIR="$CI_PROJECT_DIR"
GALAXY_FILE="$COLLECTION_DIR/galaxy.yml"
VERSION_FILE="$COLLECTION_DIR/VERSION"
README_FILE="$COLLECTION_DIR/README.md"
PUBLISH_DEBUG_DIR="$COLLECTION_DIR/publish_debug"

check_preflight() {
  command -v "$PYTHON_BIN" >/dev/null 2>&1 || die "Python binary '$PYTHON_BIN' not found."
  command -v tar >/dev/null 2>&1 || die "Required tool 'tar' not found in PATH."
  command -v git >/dev/null 2>&1 || die "git is required to synchronise shared assets."
  local py_version
  py_version="$("$PYTHON_BIN" -V 2>&1)"
  log "${PYTHON_BIN} ${py_version#Python }"
  "$PYTHON_BIN" - <<'PY'
import sys
major, minor = sys.version_info[:2]
if major < 3 or (major == 3 and minor < 10):
    print("Python >= 3.10 is required for ansible-core 2.16.x", file=sys.stderr)
    sys.exit(1)
PY
  if command -v ansible-galaxy >/dev/null 2>&1; then
    log "ansible-galaxy $(ansible-galaxy --version | head -n1)"
  else
    warn "ansible-galaxy not yet installed"
  fi
}

require_file() {
  local path="$1"
  [[ -f "$path" ]] || die "Required file '$path' missing."
}

validate_galaxy_yaml() {
  require_file "$GALAXY_FILE"
  require_file "$VERSION_FILE"
  require_file "$README_FILE"
  "$PYTHON_BIN" - <<'PY' "$GALAXY_FILE" "$VERSION_FILE" "${CI_COMMIT_TAG:-}"
import sys, yaml, re
from pathlib import Path

galaxy = Path(sys.argv[1])
version_file = Path(sys.argv[2])
ci_tag = sys.argv[3]

data = yaml.safe_load(galaxy.read_text())
required = ["namespace", "name", "version", "readme"]
missing = [key for key in required if not data.get(key)]
if missing:
    print(f"ERROR: galaxy.yml missing keys: {', '.join(missing)}", file=sys.stderr)
    sys.exit(1)

version_yaml = str(data["version"]).strip()
version_txt = version_file.read_text().strip()
if version_yaml != version_txt:
    print(f"ERROR: VERSION ({version_txt}) mismatches galaxy.yml version ({version_yaml}).", file=sys.stderr)
    sys.exit(1)

if ci_tag:
    if not re.fullmatch(r"v\d+\.\d+\.\d+", ci_tag):
        print(f"ERROR: CI_COMMIT_TAG ({ci_tag}) must follow vX.Y.Z.", file=sys.stderr)
        sys.exit(1)
    expected = f"v{version_yaml}"
    if ci_tag != expected:
        print(f"ERROR: CI_COMMIT_TAG ({ci_tag}) != {expected}.", file=sys.stderr)
        sys.exit(1)

ignore = set(data.get("build_ignore", []))
for must in ("galaxy.yml", "README.md"):
    if must in ignore:
        print(f"WARNING: build_ignore contains '{must}'. Artifact may be invalid.", file=sys.stderr)
PY
}

ensure_source_date_epoch() {
  if [[ -z "${SOURCE_DATE_EPOCH:-}" ]]; then
    if git -C "$COLLECTION_DIR" rev-parse --git-dir >/dev/null 2>&1; then
      export SOURCE_DATE_EPOCH="$(git -C "$COLLECTION_DIR" log -1 --pretty=%ct)"
    else
      export SOURCE_DATE_EPOCH="$(date +%s)"
    fi
  fi
}

prepare_layout() {
  local base="/tmp/ansible_collections/ansible_collections/${COLLECTION_NAMESPACE}"
  mkdir -p "$base"
  ln -sfn "$COLLECTION_DIR" "$base/${COLLECTION_NAME}"
  export ANSIBLE_CONFIG="$COLLECTION_DIR/ansible.cfg"
  export ANSIBLE_COLLECTIONS_PATH="/tmp/ansible_collections:${COLLECTION_DIR}/../..:${COLLECTION_DIR}/collections:/usr/share/ansible/collections"
  export ANSIBLE_ROLES_PATH="$COLLECTION_DIR/roles:/usr/share/ansible/roles:/etc/ansible/roles"
}

install_dependencies() {
  log "Installing ansible-core ${ANSIBLE_CORE_VERSION}"
  "$PYTHON_BIN" -m pip install --upgrade pip >/dev/null
  "$PYTHON_BIN" -m pip install "ansible-core==${ANSIBLE_CORE_VERSION}" >/dev/null
}

backup_cache_dirs() {
  CACHE_BACKUP="$(mktemp -d)"
  [[ -d "$COLLECTION_DIR/.cache" ]] && mv "$COLLECTION_DIR/.cache" "$CACHE_BACKUP/.cache"
  [[ -d "$COLLECTION_DIR/pip-wheel-metadata" ]] && mv "$COLLECTION_DIR/pip-wheel-metadata" "$CACHE_BACKUP/pip-wheel-metadata"
}

restore_cache_dirs() {
  rm -rf "$COLLECTION_DIR/.cache" "$COLLECTION_DIR/pip-wheel-metadata"
  [[ -d "$CACHE_BACKUP/.cache" ]] && mv "$CACHE_BACKUP/.cache" "$COLLECTION_DIR/.cache"
  [[ -d "$CACHE_BACKUP/pip-wheel-metadata" ]] && mv "$CACHE_BACKUP/pip-wheel-metadata" "$COLLECTION_DIR/pip-wheel-metadata"
  rm -rf "$CACHE_BACKUP"
}

find_artifact() {
  local pattern="$COLLECTION_DIR/$ARTIFACT_DIR/${COLLECTION_NAMESPACE}-${COLLECTION_NAME}-"*.tar.gz
  mapfile -t files < <(ls -1t $pattern 2>/dev/null || true)
  [[ ${#files[@]} -eq 0 ]] && die "No artifact found in $ARTIFACT_DIR."
  if [[ ${#files[@]} -gt 1 ]]; then
    warn "Multiple artifacts found; using newest ${files[0]}"
  fi
  printf '%s\n' "${files[0]}"
}

inspect_artifact() {
  local artifact="$(find_artifact)"
  log "Top entries in $(basename "$artifact")"
  tar -tzf "$artifact" | head -n 30

  rm -rf "$PUBLISH_DEBUG_DIR"
  mkdir -p "$PUBLISH_DEBUG_DIR"
  "$PYTHON_BIN" - <<'PY' "$artifact" "$PUBLISH_DEBUG_DIR"
import tarfile, sys
from pathlib import Path

artifact = Path(sys.argv[1])
debug_dir = Path(sys.argv[2])
debug_dir.mkdir(parents=True, exist_ok=True)
report = debug_dir / "top_entries.csv"

with tarfile.open(artifact, "r:gz") as tf, report.open("w", encoding="utf-8") as fh:
    fh.write("path,size_bytes\n")
    members = sorted(tf.getmembers(), key=lambda m: m.size, reverse=True)
    for member in members[:50]:
        fh.write(f"{member.name},{member.size}\n")
        if member.size > 20 * 1024 * 1024:
            print(f"WARNING: Large entry {member.name} ({member.size} bytes)", file=sys.stderr)

mandatory = {"galaxy.yml", "MANIFEST.json", "FILES.json"}
with tarfile.open(artifact, "r:gz") as tf:
    names = {member.name for member in tf.getmembers()}
    missing = mandatory - names
    if missing:
        print(f"ERROR: Missing required file(s) {', '.join(sorted(missing))}", file=sys.stderr)
        sys.exit(1)
PY
}

generate_sbom() { :; }
sign_artifact() { :; }

galaxy_publish_build() {
  check_preflight
  validate_galaxy_yaml
  ensure_source_date_epoch
  install_dependencies
  prepare_layout
  backup_cache_dirs

  local tmp_dir
  tmp_dir="$(mktemp -d)"
  rm -rf "$COLLECTION_DIR/$ARTIFACT_DIR"
  ansible-galaxy collection build --force --output-path "$tmp_dir"
  mkdir -p "$COLLECTION_DIR/$ARTIFACT_DIR"
  mv "$tmp_dir/${COLLECTION_NAMESPACE}-${COLLECTION_NAME}-"*.tar.gz "$COLLECTION_DIR/$ARTIFACT_DIR/"
  rm -rf "$tmp_dir"

  restore_cache_dirs

  log "Artifacts in $ARTIFACT_DIR"
  ls -alh "$COLLECTION_DIR/$ARTIFACT_DIR"

  inspect_artifact
  generate_sbom
  sign_artifact
}

galaxy_publish_publish() {
  local artifact="$(find_artifact)"
  if [[ "$DRY_RUN" == true ]]; then
    log "[dry-run] Would publish $(basename "$artifact") to $GALAXY_SERVER"
    return 0
  fi

  install_dependencies
  log "Publishing $(basename "$artifact") to $GALAXY_SERVER"
  ansible-galaxy collection publish "$artifact" --server "$GALAXY_SERVER" --token "$GALAXY_TOKEN"
}

galaxy_publish_list() {
  if [[ -d "$COLLECTION_DIR/$ARTIFACT_DIR" ]]; then
    ls -alh "$COLLECTION_DIR/$ARTIFACT_DIR"
  else
    warn "No artifacts present in $ARTIFACT_DIR"
  fi
}

verify_install() {
  local artifact="$(find_artifact)"
  local tmp_install="$(mktemp -d)"
  log "Installing artifact into temp path $tmp_install"
  ANSIBLE_COLLECTIONS_PATH="$tmp_install" ansible-galaxy collection install "$artifact" --force >/dev/null
  if ! ANSIBLE_COLLECTIONS_PATH="$tmp_install" ansible-doc -t role -l | grep -q "^${COLLECTION_NAMESPACE}.${COLLECTION_NAME}."; then
    die "ansible-doc verification failed; role not visible."
  fi
  rm -rf "$tmp_install"
  log "Verification succeeded"
}

case "$COMMAND" in
  build)
    galaxy_publish_build
    ;;
  publish)
    check_preflight
    galaxy_publish_publish
    ;;
  all)
    galaxy_publish_build
    check_preflight
    galaxy_publish_publish
    ;;
  list)
    galaxy_publish_list
    ;;
  verify)
    galaxy_publish_build
    verify_install
    ;;
  *)
    usage
    exit 2
    ;;
esac
