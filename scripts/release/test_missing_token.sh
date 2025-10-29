#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
cd "$PROJECT_ROOT"

make sync-shared >/dev/null

COLLECTION_NAMESPACE="${COLLECTION_NAMESPACE:-litpublic}" \
COLLECTION_NAME="${COLLECTION_NAME:-foundation_services}" \
PYTHON_BIN="${PYTHON_BIN:-python3}" \
./scripts/galaxy_publish.sh build >/dev/null

LOG_FILE="$(mktemp)"
trap 'rm -f "$LOG_FILE"' EXIT

if COLLECTION_NAMESPACE="${COLLECTION_NAMESPACE:-litpublic}" \
   COLLECTION_NAME="${COLLECTION_NAME:-foundation_services}" \
   GALAXY_TOKEN="" \
   PYTHON_BIN="${PYTHON_BIN:-python3}" \
   ./scripts/galaxy_publish.sh publish >"$LOG_FILE" 2>&1; then
  echo "Publish succeeded without token when it should have failed" >&2
  exit 1
fi

grep -q "GALAXY_TOKEN" "$LOG_FILE" || { echo "Missing token error not descriptive" >&2; exit 1; }

rm -f "$LOG_FILE"

echo "Missing token test OK"
