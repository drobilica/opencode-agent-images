# OpenCode Agent Images

Small, reusable container images for OpenCode coding agents and language toolchains.

## Images

| Image | Documentation | Pull |
| --- | --- | --- |
| Go | [Golang image](golang/README.md) | `ghcr.io/drobilica/opencode-agent-images:golang-<version>` |

Images run as a non-root `opencode` user and include no project files or credentials. Versioned images are published from release tags; use a specific version or an image digest.

## Maintenance

Dependabot updates Docker and GitHub Actions dependencies. A weekly workflow opens one pull request for stable OpenCode updates, including verified Linux asset checksums.

## License

See [LICENSE](LICENSE).
