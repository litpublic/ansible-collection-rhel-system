FROM python:3.11-slim

ENV PIP_NO_CACHE_DIR=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        bash \
        build-essential \
        ca-certificates \
        curl \
        docker.io \
        git \
        iproute2 \
        openssh-client \
        python3-dev \
        rsync \
        sshpass && \
    rm -rf /var/lib/apt/lists/*

RUN update-ca-certificates

ARG TARGETARCH
RUN set -euo pipefail; \
    case "${TARGETARCH}" in \
        amd64) DOCKER_ARCH="x86_64" ;; \
        arm64) DOCKER_ARCH="aarch64" ;; \
        *) echo "Unsupported TARGETARCH: ${TARGETARCH}" >&2; exit 1 ;; \
    esac; \
    curl -fsSL "https://download.docker.com/linux/static/stable/${DOCKER_ARCH}/docker-27.3.1.tgz" -o /tmp/docker.tgz && \
    tar --extract --file /tmp/docker.tgz --directory /usr/local/bin --strip-components=1 docker/docker && \
    rm /tmp/docker.tgz

RUN python -m pip install --upgrade pip setuptools && \
    pip install \
        ansible-core==2.16.9 \
        molecule[docker]==25.9.0 \
        molecule-plugins[docker]==25.8.12 \
        ansible-lint==24.6.0 \
        yamllint==1.35.1

COPY ansible-galaxy-requirements.yml /tmp/ansible-galaxy-requirements.yml
RUN ansible-galaxy collection install -r /tmp/ansible-galaxy-requirements.yml

WORKDIR /workspace

CMD ["/bin/bash"]
