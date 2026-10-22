# Coding-Agent Development Images

Reusable, non-root development images for OpenCode and Codex. Each image family
is released independently, and its public version is the exact packaged coding
agent version.

## Images

| Image | Agent | Toolchain | Versioning |
| --- | --- | --- | --- |
| [OpenCode v2 Go Dev](opencode-v2-golang-dev/README.md) | OpenCode v2 | Go | exact upstream version |
| [Codex Generic Dev](codex-generic-dev/README.md) | Codex | Go, Python, uv | Codex version |

Images are published as independent GHCR packages:

```text
ghcr.io/drobilica/opencode-v2-golang-dev
ghcr.io/drobilica/codex-generic-dev
```

Use the exact agent-version tag for normal deployments. `latest` is a moving
convenience tag and points to the same digest as the exact tag at publication
time. For absolute reproducibility, pin the OCI digest:

```bash
docker pull ghcr.io/drobilica/opencode-v2-golang-dev:<agent-version>
docker pull ghcr.io/drobilica/opencode-v2-golang-dev@sha256:<digest>
```

Exact-version tags are immutable. Consumers must use one of the two active
family packages.

OpenCode v2 extends the official `ghcr.io/anomalyco/opencode` image, pinned by
upstream version and multi-platform digest. This repository adds Go, basic
development tools, and a non-root user. Its releases remain marked as prereleases.

OpenCode v1 is retired: its build, release workflow, and dependency automation
have been removed. Existing immutable tags and releases remain available.

## Supply chain

Release images include BuildKit SPDX SBOM and maximum-mode provenance
attestations, OCI source/version/revision/documentation/license metadata, a
visible Trivy vulnerability report, and a keyless Sigstore signature created
with GitHub Actions OIDC. Verify a signature against the exact digest and the
reusable release workflow identity shown in its GitHub Release:

```bash
cosign verify \
  --certificate-identity "https://github.com/drobilica/opencode-agent-images/.github/workflows/reusable-image-release.yml@refs/tags/opencode-v2-golang-dev-v<agent-version>" \
  --certificate-oidc-issuer "https://token.actions.githubusercontent.com" \
  ghcr.io/drobilica/opencode-v2-golang-dev@sha256:<digest>
```

## Architectures

Release workflows build and run smoke tests for `linux/amd64` and
`linux/arm64` (arm64 through QEMU on GitHub-hosted amd64 runners) before
publishing a multi-platform OCI image. This validates binary startup and the
required toolchain on both platforms; it is not native-arm performance testing.

## Runtime data

No credentials, project files, repository URLs, or agent state are baked into
the images. Mount workspaces and state, and pass credentials only at runtime.

## Maintenance

Dependabot covers the active Docker image directories and GitHub Actions,
including the upstream OpenCode image and its digest. A daily workflow opens
Codex update PRs with verified Linux asset checksums. Automation PRs validate
the affected image and are never auto-merged. OpenCode updates must keep the
upstream image tag/digest and `OPENCODE_VERSION` aligned; release validation
checks the binary's reported version.

Release routing metadata lives in [images.json](images.json).

## License

See [LICENSE](LICENSE).
