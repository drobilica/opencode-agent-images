FROM golang:1.27.1-bookworm@sha256:648f440f42a0958804efb24df176f806f9d353b41f1c0627f666428e40310f6b

ARG OPENCODE_VERSION=1.18.29
ARG IMAGE_VERSION=dev
ARG IMAGE_REVISION=dev
ARG TARGETARCH

LABEL org.opencontainers.image.title="OpenCode v1 Go Dev" \
      org.opencontainers.image.description="OpenCode v1 development image with the Go toolchain" \
      org.opencontainers.image.version="${IMAGE_VERSION}" \
      org.opencontainers.image.source="https://github.com/drobilica/opencode-agent-images" \
      org.opencontainers.image.revision="${IMAGE_REVISION}" \
      org.opencontainers.image.documentation="https://github.com/drobilica/opencode-agent-images/tree/main/opencode-v1-golang-dev" \
      org.opencontainers.image.licenses="MIT"

ENV DEBIAN_FRONTEND=noninteractive \
    HOME=/home/opencode \
    GOPATH=/home/opencode/go \
    PATH=/home/opencode/.opencode/bin:/home/opencode/go/bin:${PATH} \
    XDG_CONFIG_HOME=/home/opencode/.config \
    XDG_DATA_HOME=/home/opencode/.local/share \
    XDG_STATE_HOME=/home/opencode/.local/state \
    XDG_CACHE_HOME=/home/opencode/.cache

RUN apt-get update \
    && apt-get install --no-install-recommends --yes \
        bash \
        ca-certificates \
        curl \
        gh \
        git \
        jq \
        ripgrep \
    && rm -rf /var/lib/apt/lists/* \
    && case "${TARGETARCH}" in \
        amd64) OPENCODE_ASSET=opencode-linux-x64-baseline.tar.gz OPENCODE_SHA256=03a3f2f063e23477e3e4c3a738eb389f56c5a6ecf54d6a5a6d91caab557f042d ;; \
        arm64) OPENCODE_ASSET=opencode-linux-arm64.tar.gz OPENCODE_SHA256=70baf769395ca4e7a68924026530c390eace194f3b7e4919d4efcb2aa2eed3c0 ;; \
        *) echo "Unsupported architecture: ${TARGETARCH}" >&2; exit 1 ;; \
    esac \
    && curl -fsSL "https://github.com/anomalyco/opencode/releases/download/v${OPENCODE_VERSION}/${OPENCODE_ASSET}" -o /tmp/opencode.tar.gz \
    && echo "${OPENCODE_SHA256}  /tmp/opencode.tar.gz" | sha256sum --check --strict \
    && tar -xzf /tmp/opencode.tar.gz -C /tmp \
    && install -m 0755 /tmp/opencode /usr/local/bin/opencode \
    && rm -rf /tmp/opencode /tmp/opencode.tar.gz

RUN useradd --create-home --shell /bin/bash opencode \
    && mkdir -p /workspace /home/opencode/.config /home/opencode/.local/share /home/opencode/.local/state /home/opencode/.cache /home/opencode/go \
    && chown -R opencode:opencode /workspace /home/opencode

USER opencode
WORKDIR /workspace
EXPOSE 4096

CMD ["bash"]
