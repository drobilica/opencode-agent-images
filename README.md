# Coding-Agent Development Images

Reusable, non-root development images for OpenCode and Codex. Each image family
is released independently, and its public version is the exact packaged coding
agent version.

## Images

| Image | Agent | Toolchain | Versioning |
| --- | --- | --- | --- |
| [OpenCode v1 Go Dev](opencode-v1-golang-dev/README.md) | OpenCode v1 | Go | agent version |
| [OpenCode v2 Go Dev](opencode-v2-golang-dev/README.md) | OpenCode v2 beta | Go | upstream beta identifier |
| [Codex Generic Dev](codex-generic-dev/README.md) | Codex | Go, Python, uv | Codex version |

Images are published as independent GHCR packages:

```text
ghcr.io/drobilica/opencode-v1-golang-dev
ghcr.io/drobilica/opencode-v2-golang-dev
ghcr.io/drobilica/codex-generic-dev
```

Use the exact agent-version tag for normal deployments. `latest` is a moving
convenience tag and points to the same digest as the exact tag at publication
time. For absolute reproducibility, pin the OCI digest:

```bash
docker pull ghcr.io/drobilica/opencode-v1-golang-dev:<agent-version>
docker pull ghcr.io/drobilica/opencode-v1-golang-dev@sha256:<digest>
```

Exact-version tags are immutable. Historical
`ghcr.io/drobilica/opencode-agent-images:golang-*` tags remain available but
receive no new releases.

OpenCode v2 is experimental. Its image version is the immutable identifier
reported by the upstream beta binary, currently
`0.0.0-beta-202608110357`; releases for this family are marked as prereleases.
See its [version rationale](opencode-v2-golang-dev/README.md#version-source).

## Supply chain

Release images include BuildKit SPDX SBOM and maximum-mode provenance
attestations, OCI source/version/revision/documentation/license metadata, a
visible Trivy vulnerability report, and a keyless Sigstore signature created
with GitHub Actions OIDC. Verify a signature against the exact digest and the
family workflow identity shown in its GitHub Release:

```bash
cosign verify \
  --certificate-identity "https://github.com/drobilica/opencode-agent-images/.github/workflows/opencode-v1-golang-dev.yml@refs/tags/opencode-v1-golang-dev-v<agent-version>" \
  --certificate-oidc-issuer "https://token.actions.githubusercontent.com" \
  ghcr.io/drobilica/opencode-v1-golang-dev@sha256:<digest>
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

Dependabot covers every Docker image directory and GitHub Actions. A daily
workflow checks stable OpenCode v1 and Codex releases and opens separate update
PRs with verified Linux asset checksums. The OpenCode v2 beta is intentionally
updated manually until its upstream distribution provides a reliable current
CLI release feed. Automation PRs are validated by the affected image workflow
and are never auto-merged.

Release routing metadata lives in [images.json](images.json).

## License

See [LICENSE](LICENSE).
