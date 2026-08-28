# OpenCode Agent Images

Reusable container images for OpenCode coding agents and language-specific toolchains.

## Available Image

The Golang image is currently available. It is based on Debian Bookworm and includes:

- OpenCode `1.18.25`
- Go `1.27.0`
- `git`, GitHub CLI (`gh`), Bash, curl, jq, CA certificates, and ripgrep

The image deliberately does not include Docker, Podman, Kubernetes tooling, Helm, or project-specific dependencies.

## Build And Run

Build locally from the repository root:

```bash
docker build -f golang/Dockerfile -t opencode-agent-golang:local .
```

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

## GHCR

Images are published as:

```text
ghcr.io/drobilica/opencode-agent-images:golang-<tag>
```

Version tags are created from Git tags such as `v1.0.0` and become `golang-1.0.0`. Images are published only for release tags, so consumers can use a clear versioned tag or an image digest.

## Updates

Dependabot checks the Docker base image and GitHub Actions weekly. Routine patch-only PRs are suppressed; minor, major, and security updates remain eligible. A separate weekly workflow checks OpenCode's official stable releases and opens or updates one pull request with the version and Linux asset checksums. Go is selected by the base image tag.
