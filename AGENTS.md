# Repository Guidance

- Treat this as a public repository: never commit credentials, tokens, private infrastructure details, or machine-specific configuration.
- Keep images reusable and stack-oriented; do not add project-specific dependencies or deployment tooling.
- Minimize installed tooling and preserve non-root execution.
- Verify dependency and version changes with an image build and smoke test.
- Every change to a Dockerfile or image build workflow requires a new immutable
  image release tag before it is considered complete. Use a patch version bump
  for additive or corrective image changes, update the consuming manifest to
  that exact tag, and never overwrite an existing image tag.
- Workers and subagents do not commit. The orchestrator commits validated task changes.
