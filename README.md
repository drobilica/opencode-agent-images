# OpenCode Agent Images

Small, reusable container images for OpenCode coding agents and language toolchains.

## Images

| Image | Documentation | Pull |
| --- | --- | --- |
| Go | [Golang image](golang/README.md) | `ghcr.io/drobilica/opencode-agent-images:golang-<version>` |
| Codex generic development | [Codex image](codex-generic-dev/README.md) | `ghcr.io/drobilica/codex-generic-dev:<version>` |

Images run as a non-root `opencode` user and include no project files or credentials. Versioned images are published from release tags; use a specific version or an image digest.

## Maintenance

Dependabot updates Docker and GitHub Actions dependencies. A daily workflow checks stable Codex CLI and OpenCode releases, then opens or updates separate pull requests with verified Linux asset checksums. Normal image CI validates each pull request; updates are never auto-merged. Run it manually from **Actions → Update Codex and OpenCode dependencies → Run workflow**.

## License

See [LICENSE](LICENSE).
