#!/usr/bin/env bash
set -euo pipefail

reference="${1:-}"
[[ "${reference}" == *@sha256:* ]] || { echo "usage: $0 <image@sha256:digest>" >&2; exit 2; }

index="$(docker buildx imagetools inspect --raw "${reference}")"
mapfile -t attestations < <(jq -er '
  [.manifests[]
   | select(.annotations["vnd.docker.reference.type"] == "attestation-manifest")
   | .digest][]
' <<<"${index}")
[[ "${#attestations[@]}" -eq 2 ]] || {
  echo "Expected one attestation manifest for each of two platforms" >&2
  exit 1
}

sbom=0
provenance=0
for digest in "${attestations[@]}"; do
  manifest="$(docker buildx imagetools inspect --raw "${reference%@*}@${digest}")"
  jq -e '.layers | length >= 2' <<<"${manifest}" >/dev/null
  jq -e '.layers[] | select(.annotations["in-toto.io/predicate-type"] == "https://spdx.dev/Document")' <<<"${manifest}" >/dev/null && ((sbom += 1))
  jq -e '.layers[] | select(.annotations["in-toto.io/predicate-type"] | startswith("https://slsa.dev/provenance/"))' <<<"${manifest}" >/dev/null && ((provenance += 1))
done
[[ "${sbom}" -eq 2 && "${provenance}" -eq 2 ]]
printf 'Verified SPDX SBOM and SLSA provenance attestations for %s platforms\n' "${#attestations[@]}"
