# OpenCode v2 Go Development Image

An experimental Debian Bookworm image for OpenCode v2 agents that need Go.

## Version source

OpenCode v2 does not currently publish a `2.x` CLI release. The image pins the
upstream beta-channel package identifier `0.0.0-beta-202608110357`, and the
packaged binary reports that exact value from `opencode --version`. This is an
immutable upstream identifier; the mutable npm `beta` channel is never used as
an image version.

The newer releases in `anomalyco/opencode-beta` currently contain desktop
artifacts but no standalone Linux CLI archive, so they are not usable as the
source for this image. Releases of this family are GitHub prereleases.

## Includes

- OpenCode `0.0.0-beta-202608110357`
- Go `1.27.0`
- `git`, GitHub CLI (`gh`), Bash, curl, jq, CA certificates, and ripgrep

The image runs as the non-root `opencode` user and contains no project files or
credentials.

```bash
docker pull ghcr.io/drobilica/opencode-v2-golang-dev:0.0.0-beta-202608110357
```

See the [root README](../README.md) for digest pinning, signature verification,
and supply-chain metadata.
