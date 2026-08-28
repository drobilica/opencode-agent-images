# OpenCode Go Image

A Debian Bookworm image for OpenCode agents that need Go.

## Includes

- OpenCode `1.18.25`
- Go `1.27.0`
- `git`, GitHub CLI (`gh`), Bash, curl, jq, CA certificates, and ripgrep

The image runs as the non-root `opencode` user. It deliberately excludes Docker, Podman, Kubernetes tooling, Helm, project files, and credentials.

## Pull

Use a versioned release tag:

```bash
docker pull ghcr.io/drobilica/opencode-agent-images:golang-<version>
```

Available versions are listed in [GitHub Releases](https://github.com/drobilica/opencode-agent-images/releases).

## Build

Build locally from the repository root:

```bash
docker build -f golang/Dockerfile -t opencode-agent-golang:local .
```

## Run OpenCode Web

Run OpenCode Web with a mounted workspace and a runtime password:

```bash
docker run --rm -it \
  -p 4096:4096 \
  -e OPENCODE_SERVER_PASSWORD="${OPENCODE_SERVER_PASSWORD:?set OPENCODE_SERVER_PASSWORD}" \
  -v "$PWD:/workspace" \
  opencode-agent-golang:local \
  opencode web --hostname 0.0.0.0 --port 4096
```

Provide credentials such as `GH_TOKEN` and `OPENROUTER_API_KEY` only at runtime. Mount or otherwise persist OpenCode state externally when required. The image contains tools only and copies no project files.
