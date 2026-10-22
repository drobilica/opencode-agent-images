# OpenCode v2 Go Development Image

A thin development layer over the official `ghcr.io/anomalyco/opencode:2.1.2`
image, pinned to its multi-platform digest. Upstream packages the agent and its
native runtime for amd64 and arm64; this image adds Go `1.27.0`, C/C++ build
tools, Git, GitHub CLI, Bash, curl, jq, SSH, and CA certificates.

## Version source

The version is the real upstream CLI version `2.1.2`, verified by running the
official image. It replaces this family's historical
`0.0.0-beta-202608110357` npm beta. Releases remain marked as prereleases;
existing exact-version tags are never overwritten.

The base uses Alpine/musl. Go's toolchain is copied from the pinned official
Go image, with Alpine build tools for CGO. Projects needing glibc-specific
libraries require a different development stack.

The image runs as `opencode` (UID 1000, GID 2000), with home `/home/opencode`
and working directory `/workspace`. It starts Bash; the upstream OpenCode
entrypoint is cleared so existing shell-based consumers continue working.
No credentials or project files are included.

```bash
docker pull ghcr.io/drobilica/opencode-v2-golang-dev:2.1.2
```

Start the v2 server with `opencode serve --hostname 0.0.0.0 --port 4096`.
Use authenticated `/api/info` for health checks. Consumers must replace the
v1 `opencode web` command; password authentication is still supported.

See the [root README](../README.md) for digest pinning, signatures, and
supply-chain metadata.
