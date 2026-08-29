# Codex Generic Development Image

Reusable Debian Bookworm development image for a persistent Codex workspace.

Includes pinned Codex `0.151.0`, uv `0.12.7`, Go, Python/venv/pip, Git, GitHub
CLI, compiler and archive tools, SSH tools, search tools, and process-debugging
utilities, and Bubblewrap for Codex sandboxing. The downloaded Codex and uv assets use architecture-specific SHA-256
verification.

The image runs as UID 1000 and GID 2000. It contains no project sources,
repository URLs, credentials, Kubernetes tooling, or OpenCode state.

```bash
docker pull ghcr.io/drobilica/codex-generic-dev:0.1.0
```
