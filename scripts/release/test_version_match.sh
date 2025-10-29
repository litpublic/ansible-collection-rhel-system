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

COLLECTION_NAMESPACE="${COLLECTION_NAMESPACE:-litpublic}" \
COLLECTION_NAME="${COLLECTION_NAME:-foundation_services}" \
PYTHON_BIN="${PYTHON_BIN:-python3}" \
./scripts/galaxy_publish.sh build >/dev/null

echo "Version match test OK"
