#!/usr/bin/env bash
set -euo pipefail

family="${1:-}"
image="${2:-}"
expected="${3:-}"
platform="${4:-linux/amd64}"
revision="${5:-}"

[[ -n "${family}" && -n "${image}" && -n "${expected}" ]] || {
  echo "usage: $0 <family> <image> <agent-version> [platform] [revision]" >&2
  exit 2
}

case "${family}" in
  opencode-v2-golang-dev)
    docker run --rm --platform "${platform}" -e EXPECTED="${expected}" "${image}" sh -euxc '
      test "$(id -u)" -ne 0
      test "$(id -un)" = opencode
      test "$HOME" = /home/opencode
      test "$(opencode --version)" = "opencode v$EXPECTED"
      go version
      git --version
      gh --version
      jq --version
      printf "%s\n" "package main" "import \"C\"" "func main() { _ = C.int(1) }" > /tmp/smoke.go
      CGO_ENABLED=1 go run /tmp/smoke.go
      OPENCODE_SERVER_PASSWORD=smoke-test opencode serve --hostname 127.0.0.1 --port 4096 >/tmp/server.log 2>&1 &
      server_pid=$!
      trap "kill $server_pid" EXIT
      ready=false
      for attempt in $(seq 1 30); do
        if curl --fail --silent --user opencode:smoke-test http://127.0.0.1:4096/api/info > /tmp/info.json; then
          ready=true
          break
        fi
        kill -0 "$server_pid" || { cat /tmp/server.log; exit 1; }
        sleep 1
      done
      test "$ready" = true || { cat /tmp/server.log; exit 1; }
      jq -e --arg version "$EXPECTED" ".version == \$version" /tmp/info.json
      test "$(curl --silent --output /dev/null --write-out "%{http_code}" http://127.0.0.1:4096/api/info)" = 401
    '
    ;;
  codex-generic-dev)
    docker run --rm --platform "${platform}" -e EXPECTED="${expected}" "${image}" sh -euxc '
      test "$(id -u)" -ne 0
      test "$(id -un)" = codex
      test "$HOME" = /home/codex
      codex --version | grep -Eq "(^|[[:space:]])${EXPECTED}$"
      codex-code-mode-host --help
      go version
      python3 --version
      uv --version
      git --version
      gh --version
      jq --version
    '
    ;;
  *) echo "Unknown image family: ${family}" >&2; exit 2 ;;
esac

label() { docker image inspect --format "{{ index .Config.Labels \"$1\" }}" "${image}"; }
[[ "$(label org.opencontainers.image.version)" == "${expected}" ]]
[[ "$(label org.opencontainers.image.source)" == "https://github.com/drobilica/opencode-agent-images" ]]
[[ "$(label org.opencontainers.image.documentation)" == "https://github.com/drobilica/opencode-agent-images/tree/main/${family}" ]]
[[ "$(label org.opencontainers.image.licenses)" == "MIT" ]]
[[ -n "$(label org.opencontainers.image.title)" ]]
[[ -n "$(label org.opencontainers.image.description)" ]]
[[ -z "${revision}" || "$(label org.opencontainers.image.revision)" == "${revision}" ]]
