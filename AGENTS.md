# Repository Guidance

- Treat this as a public repository: never commit credentials, tokens, private infrastructure details, or machine-specific configuration.
- Keep images reusable and stack-oriented; do not add project-specific dependencies or deployment tooling.
- Minimize installed tooling and preserve non-root execution.
- Verify dependency and version changes with an image build and smoke test.
- Workers and subagents do not commit. The orchestrator commits validated task changes.
