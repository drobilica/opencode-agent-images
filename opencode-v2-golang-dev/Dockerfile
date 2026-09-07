FROM golang:1.27.0-bookworm@sha256:ded31c68586d2e49e760acc2e65a884b23d032e9bbbed0ae0c55abd3fcaf4452

ARG OPENCODE_VERSION=0.0.0-beta-202608110357
ARG IMAGE_VERSION=dev
ARG IMAGE_REVISION=dev
ARG TARGETARCH

LABEL org.opencontainers.image.title="OpenCode v2 Go Dev" \
      org.opencontainers.image.description="Experimental OpenCode v2 development image with the Go toolchain" \
      org.opencontainers.image.version="${IMAGE_VERSION}" \
      org.opencontainers.image.source="https://github.com/drobilica/opencode-agent-images" \
      org.opencontainers.image.revision="${IMAGE_REVISION}" \
      org.opencontainers.image.documentation="https://github.com/drobilica/opencode-agent-images/tree/main/opencode-v2-golang-dev" \
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
        amd64) OPENCODE_PACKAGE=opencode-linux-x64-baseline OPENCODE_SHA256=ea8a185a14b6e6c00c27ba777b046e9c5a5dbe965c68df2412fcebbdcb238f92 ;; \
        arm64) OPENCODE_PACKAGE=opencode-linux-arm64 OPENCODE_SHA256=ac0960265283499a3c31e4069d25f5d3f0e411e5b4bb6d16f634a606bf255c7a ;; \
        *) echo "Unsupported architecture: ${TARGETARCH}" >&2; exit 1 ;; \
    esac \
    && curl -fsSL "https://registry.npmjs.org/${OPENCODE_PACKAGE}/-/${OPENCODE_PACKAGE}-${OPENCODE_VERSION}.tgz" -o /tmp/opencode.tgz \
    && echo "${OPENCODE_SHA256}  /tmp/opencode.tgz" | sha256sum --check --strict \
    && tar -xzf /tmp/opencode.tgz -C /tmp package/bin/opencode \
    && install -m 0755 /tmp/package/bin/opencode /usr/local/bin/opencode \
    && rm -rf /tmp/opencode.tgz /tmp/package

RUN useradd --create-home --shell /bin/bash opencode \
    && mkdir -p /workspace /home/opencode/.config /home/opencode/.local/share /home/opencode/.local/state /home/opencode/.cache /home/opencode/go \
    && chown -R opencode:opencode /workspace /home/opencode

USER opencode
WORKDIR /workspace
EXPOSE 4096

CMD ["bash"]
