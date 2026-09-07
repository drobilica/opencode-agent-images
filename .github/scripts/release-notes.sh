#!/usr/bin/env bash
set -euo pipefail

family="${1:-}"
digest="${2:-}"
trivy_json="${3:-}"
output="${4:-}"
root="$(git rev-parse --show-toplevel)"
[[ -n "${family}" && "${digest}" =~ ^sha256:[0-9a-f]{64}$ && -f "${trivy_json}" && -n "${output}" ]] || {
  echo "usage: $0 <family> <sha256:digest> <trivy.json> <notes.md>" >&2
  exit 2
}

metadata="$(bash "${root}/.github/scripts/image-metadata.sh" "${family}")"
value() { sed -n "s/^$1=//p" <<<"${metadata}"; }
package="$(value package)"
version="$(value agent_version)"
prefix="$(value release_tag_prefix)"
title="$(value title)"
tag="${prefix}${version}"
reference="${package}@${digest}"

case "${family}" in
  opencode-v1-golang-dev) upstream_url="https://github.com/anomalyco/opencode/releases/tag/v${version}" ;;
  opencode-v2-golang-dev) upstream_url="https://www.npmjs.com/package/opencode-ai/v/${version}" ;;
  codex-generic-dev) upstream_url="https://github.com/openai/codex/releases/tag/rust-v${version}" ;;
  *) echo "Unknown family: ${family}" >&2; exit 2 ;;
esac

agent_report="$(docker run --rm --platform linux/amd64 "${reference}" sh -c 'opencode --version 2>/dev/null || codex --version')"
go_version="$(docker run --rm --platform linux/amd64 "${reference}" sh -c 'go version | awk "{print \$3}"')"
python_version="$(docker run --rm --platform linux/amd64 "${reference}" sh -c 'python3 --version 2>/dev/null | awk "{print \$2}" || true')"
uv_version="$(docker run --rm --platform linux/amd64 "${reference}" sh -c 'uv --version 2>/dev/null | awk "{print \$2}" || true')"
base_image="$(sed -n '1s/^FROM //p' "${root}/$(value dockerfile)")"
[[ -n "${python_version}" ]] || python_version="not included"
[[ -n "${uv_version}" ]] || uv_version="not included"

previous="none (first agent-versioned release)"
while IFS= read -r candidate; do
  [[ "${candidate}" == "${tag}" ]] && continue
  candidate_version="${candidate#${prefix}}"
  candidate_agent_version="$(git show "${candidate}:$(value dockerfile)" 2>/dev/null | sed -nE "s/^ARG $(value agent_version_arg)=([^[:space:]]+)$/\1/p" || true)"
  if [[ "${candidate_version}" == "${candidate_agent_version}" ]]; then
    previous="${candidate_version}"
    break
  fi
done < <(git tag --list "${prefix}*" --sort=-v:refname)

critical="$(jq '[.Results[]?.Vulnerabilities[]? | select(.Severity == "CRITICAL")] | length' "${trivy_json}")"
high="$(jq '[.Results[]?.Vulnerabilities[]? | select(.Severity == "HIGH")] | length' "${trivy_json}")"
identity="${SIGNING_IDENTITY:-https://github.com/drobilica/opencode-agent-images/.github/workflows/reusable-image-release.yml@refs/tags/${tag}}"

cat >"${output}" <<EOF
## Image

\`${package}:${version}\`

## Moving tag

\`${package}:latest\`

## Components

- OpenCode/Codex: \`${agent_report}\`
- Go: \`${go_version}\`
- Python: \`${python_version}\`
- uv: \`${uv_version}\`
- Base image: \`${base_image}\`

## Platforms

- \`linux/amd64\`
- \`linux/arm64\` (runtime-smoke-tested through QEMU)

## Digest

\`${digest}\`

## Changes

\`${previous}\` → \`${version}\`

Upstream release/package: ${upstream_url}

## Supply chain

- BuildKit SPDX SBOM: attached and verified for both platforms
- BuildKit SLSA provenance (mode=max): attached and verified for both platforms
- Keyless Sigstore signature: verified for \`${identity}\`
- Trivy (reported, non-blocking): ${critical} CRITICAL, ${high} HIGH findings

## Pull

\`\`\`bash
docker pull ${package}:${version}
\`\`\`

Immutable pull:

\`\`\`bash
docker pull ${reference}
\`\`\`
EOF

printf 'Generated release notes for %s %s\n' "${title}" "${version}"
