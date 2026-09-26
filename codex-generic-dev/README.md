# Codex Generic Development Image

Reusable Debian Bookworm development image for a persistent Codex workspace.

Includes pinned Codex `0.157.1`, uv `0.12.7`, Go, Python/venv/pip, Git, GitHub
CLI, compiler and archive tools, SSH tools, search tools, and process-debugging
utilities, and Bubblewrap for Codex sandboxing. The downloaded Codex and uv assets use architecture-specific SHA-256
verification.

The Codex app-server companion executable, `codex-code-mode-host`, is included
for remote Code Mode support.

The image runs as UID 1000 and GID 2000. It contains no project sources,
repository URLs, credentials, Kubernetes tooling, or OpenCode state.

Use the exact packaged Codex version for normal deployments:

```bash
docker pull ghcr.io/drobilica/codex-generic-dev:0.157.1
```

See the [root README](../README.md) for digest pinning, signature verification,
and supply-chain metadata.
