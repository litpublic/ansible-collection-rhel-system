#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$PROJECT_ROOT"

COLLECTION_NAMESPACE="${COLLECTION_NAMESPACE:-litpublic}" \
COLLECTION_NAME="${COLLECTION_NAME:-foundation_services}" \
PYTHON_BIN="${PYTHON_BIN:-python3}" \
./scripts/galaxy_publish.sh build >/dev/null

LOG_FILE="$(mktemp)"
trap 'rm -f "$LOG_FILE"' EXIT

COLLECTION_NAMESPACE="${COLLECTION_NAMESPACE:-litpublic}" \
COLLECTION_NAME="${COLLECTION_NAME:-foundation_services}" \
GALAXY_SERVER="https://galaxy.ansible.com" \
PYTHON_BIN="${PYTHON_BIN:-python3}" \
./scripts/galaxy_publish.sh publish --dry-run >"$LOG_FILE"

grep -q "dry-run" "$LOG_FILE" || { echo "Dry run log missing" >&2; exit 1; }

echo "Dry-run publish test OK"
