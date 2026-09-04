FROM golang:1.27.0-bookworm@sha256:ded31c68586d2e49e760acc2e65a884b23d032e9bbbed0ae0c55abd3fcaf4452

ARG CODEX_VERSION=0.153.3
ARG UV_VERSION=0.12.7
ARG IMAGE_VERSION=dev
ARG TARGETARCH

LABEL org.opencontainers.image.version="${IMAGE_VERSION}"

ENV DEBIAN_FRONTEND=noninteractive \
    HOME=/home/codex \
    GOPATH=/home/codex/go \
    PATH=/home/codex/.local/bin:/home/codex/go/bin:${PATH} \
    XDG_CONFIG_HOME=/home/codex/.config \
    XDG_DATA_HOME=/home/codex/.local/share \
    XDG_STATE_HOME=/home/codex/.local/state \
    XDG_CACHE_HOME=/home/codex/.cache

RUN apt-get update \
    && apt-get install --no-install-recommends --yes \
        bash bubblewrap ca-certificates curl file gcc g++ make pkg-config \
        git gh jq ripgrep fd-find \
        less lsof procps psmisc strace \
        openssh-client tar unzip xz-utils zip \
        python3 python3-pip python3-venv \
    && rm -rf /var/lib/apt/lists/* \
    && case "${TARGETARCH}" in \
        amd64) CODEX_ASSET=codex-package-x86_64-unknown-linux-musl.tar.gz CODEX_SHA256=47bb1fb36fb1dbd5fe1af3eb0db422ffb4c3c38d9c1762c7618a9bed46c44a63 UV_ASSET=uv-x86_64-unknown-linux-gnu.tar.gz UV_SHA256=788f18abea7c5f55d6216e4f5613fd89d4d59b631efeec117b2b07fe72f1da21 ;; \
        arm64) CODEX_ASSET=codex-package-aarch64-unknown-linux-musl.tar.gz CODEX_SHA256=53d4604d339cdc87f1c396aca80c2addc8e092987b1b15c5f34dcda1fa54748a UV_ASSET=uv-aarch64-unknown-linux-gnu.tar.gz UV_SHA256=66393193038dd7eb108abd7a218d9cec04ac70ab98242b0720fa94de19223b7c ;; \
        *) echo "Unsupported architecture: ${TARGETARCH}" >&2; exit 1 ;; \
    esac \
    && curl -fsSL "https://github.com/openai/codex/releases/download/rust-v${CODEX_VERSION}/${CODEX_ASSET}" -o /tmp/codex.tar.gz \
    && echo "${CODEX_SHA256}  /tmp/codex.tar.gz" | sha256sum --check --strict \
    && tar -xzf /tmp/codex.tar.gz -C /opt \
    && install -m 0755 /opt/bin/codex /usr/local/bin/codex \
    && install -m 0755 /opt/bin/codex-code-mode-host /usr/local/bin/codex-code-mode-host \
    && curl -fsSL "https://github.com/astral-sh/uv/releases/download/${UV_VERSION}/${UV_ASSET}" -o /tmp/uv.tar.gz \
    && echo "${UV_SHA256}  /tmp/uv.tar.gz" | sha256sum --check --strict \
    && tar -xzf /tmp/uv.tar.gz -C /tmp \
    && install -m 0755 /tmp/uv-*/uv /usr/local/bin/uv \
    && install -m 0755 /tmp/uv-*/uvx /usr/local/bin/uvx \
    && rm -rf /tmp/codex.tar.gz /tmp/uv.tar.gz /tmp/uv-* /opt

RUN groupadd --gid 2000 codex \
    && useradd --uid 1000 --gid 2000 --create-home --shell /bin/bash codex \
    && mkdir -p /home/codex/.codex /home/codex/.cache /home/codex/.config /home/codex/.local /home/codex/go /home/codex/workspace \
    && chown -R codex:codex /home/codex

USER codex
WORKDIR /home/codex/workspace
EXPOSE 4500

CMD ["bash"]
