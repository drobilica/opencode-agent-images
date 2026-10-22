ARG OPENCODE_VERSION=2.1.2

FROM docker.io/library/golang:1.27.0-bookworm@sha256:ded31c68586d2e49e760acc2e65a884b23d032e9bbbed0ae0c55abd3fcaf4452 AS go
FROM ghcr.io/anomalyco/opencode:${OPENCODE_VERSION}@sha256:d91c668b3390b5416fee4803ffd0936ad30c3e118f550e7ad6d2fabc8b974b00

ARG IMAGE_VERSION=dev
ARG IMAGE_REVISION=dev

LABEL org.opencontainers.image.title="OpenCode v2 Go Dev" \
      org.opencontainers.image.description="Official OpenCode v2 image with the Go development toolchain" \
      org.opencontainers.image.version="${IMAGE_VERSION}" \
      org.opencontainers.image.source="https://github.com/drobilica/opencode-agent-images" \
      org.opencontainers.image.revision="${IMAGE_REVISION}" \
      org.opencontainers.image.documentation="https://github.com/drobilica/opencode-agent-images/tree/main/opencode-v2-golang-dev" \
      org.opencontainers.image.licenses="MIT"

COPY --from=go /usr/local/go /usr/local/go

RUN apk add --no-cache bash build-base ca-certificates curl git github-cli jq openssh-client \
    && addgroup -g 2000 opencode \
    && adduser -D -u 1000 -G opencode -s /bin/bash opencode \
    && mkdir -p /workspace /home/opencode/.config /home/opencode/.local/share /home/opencode/.local/state /home/opencode/.cache /home/opencode/go \
    && chown -R opencode:opencode /workspace /home/opencode

ENV HOME=/home/opencode \
    GOPATH=/home/opencode/go \
    PATH=/usr/local/go/bin:/home/opencode/go/bin:${PATH} \
    XDG_CONFIG_HOME=/home/opencode/.config \
    XDG_DATA_HOME=/home/opencode/.local/share \
    XDG_STATE_HOME=/home/opencode/.local/state \
    XDG_CACHE_HOME=/home/opencode/.cache

USER opencode
WORKDIR /workspace
EXPOSE 4096

ENTRYPOINT []
CMD ["bash"]
