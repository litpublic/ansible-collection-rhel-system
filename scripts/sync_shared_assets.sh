#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="${CI_PROJECT_DIR:-$(pwd)}"
REPO_PATH="lit4/modulix/platform/software-development-ecosystem/automation-tools/shared-assets"
REPO_URL="https://gitlab.com/${REPO_PATH}.git"
TMP_DIR="${SHARED_ASSETS_TMP:-$(mktemp -d)}"

cleanup() {
  [[ "${SHARED_ASSETS_TMP:-}" ]] || rm -rf "$TMP_DIR"
}
trap cleanup EXIT

if [[ -n "${CI_JOB_TOKEN:-}" ]]; then
  REPO_URL="https://gitlab-ci-token:${CI_JOB_TOKEN}@gitlab.com/${REPO_PATH}.git"
elif [[ -n "${GL_TOKEN:-}" ]]; then
  REPO_URL="https://oauth2:${GL_TOKEN}@gitlab.com/${REPO_PATH}.git"
elif [[ -n "${GITLAB_TOKEN:-}" ]]; then
  REPO_URL="https://oauth2:${GITLAB_TOKEN}@gitlab.com/${REPO_PATH}.git"
fi

if ! git clone --depth 1 "$REPO_URL" "$TMP_DIR" >/dev/null 2>&1; then
  cat >&2 <<'MSG'
ERROR: Unable to clone shared-assets repository.
Set GL_TOKEN or GITLAB_TOKEN with api scope (or run inside CI with CI_JOB_TOKEN).
MSG
  exit 1
fi

copy_path() {
  local src="$1"
  local dest="$2"
  if [ -d "$src" ]; then
    rm -rf "$dest"
    mkdir -p "$(dirname "$dest")"
    cp -a "$src" "$dest"
  else
    mkdir -p "$(dirname "$dest")"
    cp -f "$src" "$dest"
  fi
}

for file in \
  AGENTS.md \
  CONTRIBUTING.md \
  CODE_OF_CONDUCT.md \
  Dockerfile.test \
  pre-commit/base-config.yaml \
  ansible.cfg \
  .ansible-lint \
  .pre-commit-config.yaml \
  .yamllint.yaml \
  .releaserc.json \
  LICENSE \
  .gitignore \
  .gitlab-ci.yml; do
  copy_path "$TMP_DIR/collections/common/$file" "$PROJECT_DIR/$file"
done

for dir in \
  scripts \
  .agent \
  docker \
  molecule \
  meta; do
  copy_path "$TMP_DIR/collections/common/$dir" "$PROJECT_DIR/$dir"
done
