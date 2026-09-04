FROM golang:1.27.0-bookworm@sha256:ded31c68586d2e49e760acc2e65a884b23d032e9bbbed0ae0c55abd3fcaf4452

ARG OPENCODE_VERSION=1.18.28
ARG IMAGE_VERSION=dev
ARG TARGETARCH

LABEL org.opencontainers.image.version="${IMAGE_VERSION}"

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
        amd64) OPENCODE_ASSET=opencode-linux-x64-baseline.tar.gz OPENCODE_SHA256=e0a7018b59d8d99845a1d431d9e4a1594d221a1cbde516741b1466d2c85bff66 ;; \
        arm64) OPENCODE_ASSET=opencode-linux-arm64.tar.gz OPENCODE_SHA256=ccb0d39467eeccc52cdfe1cccad0114304366cb42073b906d970a487ca5b4497 ;; \
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
