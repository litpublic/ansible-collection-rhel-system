#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TMP_CLONE="$(mktemp -d)"
cleanup() { rm -rf "$TMP_CLONE"; }
trap cleanup EXIT

cp -R "$PROJECT_ROOT"/. "$TMP_CLONE"/
rm -rf "$TMP_CLONE"/.git
cd "$TMP_CLONE"

export SOURCE_DATE_EPOCH=${SOURCE_DATE_EPOCH:-$(git -C "$PROJECT_ROOT" log -1 --pretty=%ct 2>/dev/null || date +%s)}

COLLECTION_NAMESPACE="${COLLECTION_NAMESPACE:-lit}" \
COLLECTION_NAME="${COLLECTION_NAME:-foundation_services}" \
PYTHON_BIN="${PYTHON_BIN:-python3}" \
./scripts/galaxy_publish.sh build >/dev/null

sha_one=$(sha256sum dist/*.tar.gz | awk '{print $1}')

rm -rf dist publish_debug

COLLECTION_NAMESPACE="${COLLECTION_NAMESPACE:-lit}" \
COLLECTION_NAME="${COLLECTION_NAME:-foundation_services}" \
PYTHON_BIN="${PYTHON_BIN:-python3}" \
./scripts/galaxy_publish.sh build >/dev/null

sha_two=$(sha256sum dist/*.tar.gz | awk '{print $1}')

if [[ "$sha_one" != "$sha_two" ]]; then
  echo "Artifacts differ between builds: $sha_one vs $sha_two" >&2
  exit 1
fi

echo "Rebuild reproducibility OK"
