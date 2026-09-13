# Repository Guidance

- Treat this as a public repository: never commit credentials, tokens, private infrastructure details, or machine-specific configuration.
- Keep images reusable and stack-oriented; do not add project-specific dependencies or deployment tooling.
- Minimize installed tooling and preserve non-root execution.
- Verify dependency and version changes with an image build and smoke test.
- Changes that alter a Dockerfile or the produced runtime, including a packaged
  agent version change, require validation and a new legitimate immutable release
  of each affected family before consumers are updated. Public image versions
  are the packaged coding-agent version, not independent repository or image
  patch versions. Use the family-specific Git tag prefix from `images.json`, and
  never overwrite a released exact-version tag.
- CI-only trigger, validation, or orchestration changes that do not alter the
  produced runtime must be validated but must not invent an agent version or
  publish an artificial image release.
- `latest` is the only moving tag. It must be published with the exact-version
  tag so both resolve to the same digest at publication time.
- OpenCode v2 uses its real immutable upstream beta/channel identifier and its
  GitHub Release is a prerelease; never invent a `2.0.0` version.
- Published images require OCI metadata, BuildKit SBOM and provenance,
  digest-based keyless Cosign signing, Trivy reporting, and useful per-image
  release notes.
- Workers and subagents do not commit. The orchestrator commits validated task changes.
