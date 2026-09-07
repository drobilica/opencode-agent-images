#!/usr/bin/env bash
set -euo pipefail

family="${1:-}"
tag_name="${2:-}"
root="$(git rev-parse --show-toplevel)"
manifest="${root}/images.json"

[[ -n "${family}" ]] || { echo "usage: $0 <family> [git-tag]" >&2; exit 2; }
jq -e 'type == "array" and length == 3' "${manifest}" >/dev/null
[[ "$(jq --arg family "${family}" '[.[] | select(.family == $family)] | length' "${manifest}")" == 1 ]] || {
  echo "Expected exactly one images.json entry for ${family}" >&2
  exit 1
}

field() { jq -er --arg family "${family}" ".[] | select(.family == \$family) | .$1" "${manifest}"; }
dockerfile="$(field dockerfile)"
version_arg="$(field agent_version_arg)"
[[ -f "${root}/${dockerfile}" ]] || { echo "Missing Dockerfile: ${dockerfile}" >&2; exit 1; }
version="$(sed -nE "s/^ARG ${version_arg}=([^[:space:]]+)$/\1/p" "${root}/${dockerfile}")"
[[ -n "${version}" && "$(grep -Ec "^ARG ${version_arg}=" "${root}/${dockerfile}")" == 1 ]] || {
  echo "Could not resolve one ${version_arg} from ${dockerfile}" >&2
  exit 1
}
[[ "${version}" =~ ^[0-9]+\.[0-9]+\.[0-9]+([.-][0-9A-Za-z.-]+)?$ ]] || {
  echo "Invalid agent version: ${version}" >&2
  exit 1
}

prefix="$(field release_tag_prefix)"
if [[ -n "${tag_name}" && "${tag_name}" != "${prefix}${version}" ]]; then
  echo "Tag ${tag_name} does not match packaged agent version ${prefix}${version}" >&2
  exit 1
fi

emit() {
  printf '%s=%s\n' "$1" "$2"
  [[ -z "${GITHUB_OUTPUT:-}" ]] || printf '%s=%s\n' "$1" "$2" >>"${GITHUB_OUTPUT}"
}

emit family "${family}"
emit title "$(field title)"
emit description "$(field description)"
emit agent "$(field agent)"
emit channel "$(field channel)"
emit path "$(field path)"
emit dockerfile "${dockerfile}"
emit package "$(field package)"
emit release_tag_prefix "${prefix}"
emit prerelease "$(field prerelease)"
emit agent_version_arg "${version_arg}"
emit agent_version "${version}"
