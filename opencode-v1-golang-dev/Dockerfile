FROM golang:1.27.0-bookworm@sha256:ded31c68586d2e49e760acc2e65a884b23d032e9bbbed0ae0c55abd3fcaf4452

ARG OPENCODE_VERSION=1.18.32
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
        amd64) OPENCODE_ASSET=opencode-linux-x64-baseline.tar.gz OPENCODE_SHA256=763af386ef88a8cab18df00fcf055690e5a55e31a7088beabe02307142a6adce ;; \
        arm64) OPENCODE_ASSET=opencode-linux-arm64.tar.gz OPENCODE_SHA256=568461b7d4d8c19865c97e9a1102e613049c6039d01fe772154de873c1865840 ;; \
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
