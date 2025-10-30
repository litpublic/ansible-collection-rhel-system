#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT_DIR=$(cd "${SCRIPT_DIR}/.." && pwd)
IMAGE_NAME=${TEST_CONTAINER_IMAGE:-lit-foundation_services-test:latest}

DOCKER_BUILDKIT=1 docker build -f "${ROOT_DIR}/Dockerfile.test" -t "${IMAGE_NAME}" "${ROOT_DIR}" >/dev/null

DOCKER_BUILDKIT=1 docker run --rm \
  -v "${ROOT_DIR}:/workspace" \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -e ANSIBLE_CONFIG=/workspace/ansible.cfg \
  "${IMAGE_NAME}" bash -c '
    set -euo pipefail
    cd /workspace
    mkdir -p /tmp/ansible_collections/ansible_collections/litpublic
    ln -sfn /workspace /tmp/ansible_collections/ansible_collections/litpublic/foundation_services
    export ANSIBLE_COLLECTIONS_PATH="/tmp/ansible_collections:/workspace/collections:/root/.ansible/collections:/usr/share/ansible/collections"
    export ANSIBLE_ROLES_PATH="/workspace/roles:/root/.ansible/roles:/usr/share/ansible/roles:/etc/ansible/roles"
    unset ANSIBLE_COLLECTIONS_PATHS
    if [ -d .git ]; then
      pre-commit run --all-files
    else
      echo "[test-container] Skipping pre-commit (no .git directory present)"
    fi
    ansible-lint
    if [ -d molecule ]; then
      molecule test --all
    fi
  '
