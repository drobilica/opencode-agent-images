#!/usr/bin/env bash
set -euo pipefail

component="${1:-}"
case "${component}" in
  codex)
    repository=openai/codex; component_upper=CODEX; arg_name=CODEX_VERSION
    dockerfile_relative=codex-generic-dev/Dockerfile; readme_relative=codex-generic-dev/README.md
    tag_pattern='^rust-v(?<version>[0-9]{1,9}\.[0-9]{1,9}\.[0-9]{1,9})$'
    asset_amd64=codex-package-x86_64-unknown-linux-musl.tar.gz
    asset_arm64=codex-package-aarch64-unknown-linux-musl.tar.gz
    ;;
  opencode)
    repository=anomalyco/opencode; component_upper=OPENCODE; arg_name=OPENCODE_VERSION
    dockerfile_relative=golang/Dockerfile; readme_relative=golang/README.md
    tag_pattern='^v(?<version>[0-9]{1,9}\.[0-9]{1,9}\.[0-9]{1,9})$'
    asset_amd64=opencode-linux-x64-baseline.tar.gz
    asset_arm64=opencode-linux-arm64.tar.gz
    ;;
  *) echo "usage: $0 codex|opencode" >&2; exit 2 ;;
esac

repository_root="${REPOSITORY_ROOT:-$(git rev-parse --show-toplevel)}"
dockerfile="${repository_root}/${dockerfile_relative}"
readme="${repository_root}/${readme_relative}"
[[ -f "${dockerfile}" && -f "${readme}" ]] || { echo "Missing component files" >&2; exit 1; }

temporary_directory="$(mktemp -d)"
trap 'rm -rf "${temporary_directory}"' EXIT
release_file="${temporary_directory}/releases.json"
if [[ -n "${RELEASES_FIXTURE:-}" ]]; then
  cp -- "${RELEASES_FIXTURE}" "${release_file}"
else
  # GitHub's latest-release endpoint excludes drafts and prereleases. Normalize
  # its single release object to the fixture array consumed below.
  gh api --method GET "repos/${repository}/releases/latest" |
    jq -e 'if type == "object" then [.] else error("non-object latest release") end' >"${release_file}"
fi
jq -e 'type == "array"' "${release_file}" >/dev/null || { echo "Invalid release API response" >&2; exit 1; }

selected_release="$(jq -ce --arg pattern "${tag_pattern}" '
  [ .[] | select((.draft // false) == false) | select((.prerelease // false) == false)
    | select((.tag_name // "") | test($pattern))
    | . + ((.tag_name | capture($pattern)) | {version: .version}) ]
  | if length == 0 then error("no exact stable release") else sort_by(.version | split(".") | map(tonumber))[-1] end
' "${release_file}")" || { echo "No stable ${component} release found" >&2; exit 1; }
version="$(jq -er '.version' <<<"${selected_release}")"
tag="$(jq -er '.tag_name' <<<"${selected_release}")"
[[ "${version}" =~ ^[0-9]{1,9}\.[0-9]{1,9}\.[0-9]{1,9}$ ]] || { echo "Invalid selected version" >&2; exit 1; }
release_url="https://github.com/${repository}/releases/tag/${tag}"

asset_digest() {
  local name="$1" count digest
  count="$(jq --arg name "${name}" '[.assets[]? | select(.name == $name)] | length' <<<"${selected_release}")"
  [[ "${count}" == 1 ]] || { echo "Expected exactly one asset: ${name}" >&2; exit 1; }
  digest="$(jq -er --arg name "${name}" '.assets[] | select(.name == $name) | .digest' <<<"${selected_release}")" ||
    { echo "Missing digest for ${name}" >&2; exit 1; }
  [[ "${digest}" =~ ^sha256:[0-9A-Fa-f]{64}$ ]] || { echo "Invalid digest for ${name}" >&2; exit 1; }
  printf '%s\n' "${digest#sha256:}"
}
amd64_sha256="$(asset_digest "${asset_amd64}")"
arm64_sha256="$(asset_digest "${asset_arm64}")"

current_count="$(grep -Ec "^ARG ${arg_name}=" "${dockerfile}" || true)"
[[ "${current_count}" == 1 ]] || { echo "Expected one ${arg_name} ARG" >&2; exit 1; }
current_version="$(sed -nE "s/^ARG ${arg_name}=([^[:space:]]+)\$/\1/p" "${dockerfile}")"
[[ "${current_version}" =~ ^[0-9]{1,9}\.[0-9]{1,9}\.[0-9]{1,9}$ ]] || { echo "Invalid current version" >&2; exit 1; }

version_greater() {
  local newer="$1" older="$2" na nb nc oa ob oc
  IFS=. read -r na nb nc <<<"${newer}"; IFS=. read -r oa ob oc <<<"${older}"
  ((10#${na} > 10#${oa})) ||
    { ((10#${na} == 10#${oa} && 10#${nb} > 10#${ob})) ||
      ((10#${na} == 10#${oa} && 10#${nb} == 10#${ob} && 10#${nc} > 10#${oc})); }
}
output() { [[ -z "${GITHUB_OUTPUT:-}" ]] || printf '%s=%s\n' "$1" "$2" >>"${GITHUB_OUTPUT}"; }
common_outputs() {
  output previous "${current_version}"; output new "${version}"
  output tag "${tag}"; output release_url "${release_url}"
}
if [[ "${version}" == "${current_version}" ]] || ! version_greater "${version}" "${current_version}"; then
  echo "${component} ${current_version} is current (latest stable: ${version})"
  output changed false; common_outputs; exit 0
fi

docker_amd64_count="$(grep -Ec "${component_upper}_ASSET=${asset_amd64} ${component_upper}_SHA256=[[:xdigit:]]{64}" "${dockerfile}" || true)"
docker_arm64_count="$(grep -Ec "${component_upper}_ASSET=${asset_arm64} ${component_upper}_SHA256=[[:xdigit:]]{64}" "${dockerfile}" || true)"
[[ "${docker_amd64_count}" == 1 && "${docker_arm64_count}" == 1 ]] || { echo "Expected one checksum line per architecture" >&2; exit 1; }
if [[ "${component}" == codex ]]; then
  readme_count="$(grep -Ec '^Includes pinned Codex \`[0-9]+\.[0-9]+\.[0-9]+\`,' "${readme}" || true)"
else
  readme_count="$(grep -Ec '^- OpenCode \`[0-9]+\.[0-9]+\.[0-9]+\`$' "${readme}" || true)"
fi
[[ "${readme_count}" == 1 ]] || { echo "Expected one README version pin" >&2; exit 1; }

updated_dockerfile="${temporary_directory}/Dockerfile.updated"
updated_readme="${temporary_directory}/README.updated"
sed -E \
  -e "s|^ARG ${arg_name}=[^[:space:]]+\$|ARG ${arg_name}=${version}|" \
  -e "s|(${component_upper}_ASSET=${asset_amd64} ${component_upper}_SHA256=)[[:xdigit:]]{64}|\1${amd64_sha256}|" \
  -e "s|(${component_upper}_ASSET=${asset_arm64} ${component_upper}_SHA256=)[[:xdigit:]]{64}|\1${arm64_sha256}|" \
  "${dockerfile}" >"${updated_dockerfile}"
if [[ "${component}" == codex ]]; then
  sed -E "s|^Includes pinned Codex \`[0-9]+\.[0-9]+\.[0-9]+\`,|Includes pinned Codex \`${version}\`,|" "${readme}" >"${updated_readme}"
else
  sed -E "s|^- OpenCode \`[0-9]+\.[0-9]+\.[0-9]+\`\$|- OpenCode \`${version}\`|" "${readme}" >"${updated_readme}"
fi

grep -Eq "^ARG ${arg_name}=${version}\$" "${updated_dockerfile}" || { echo "Version replacement incomplete" >&2; exit 1; }
[[ "$(grep -Ec "^ARG ${arg_name}=${version}\$" "${updated_dockerfile}")" == 1 ]] || exit 1
[[ "$(grep -Ec "${component_upper}_ASSET=${asset_amd64} ${component_upper}_SHA256=${amd64_sha256}" "${updated_dockerfile}")" == 1 ]] || exit 1
[[ "$(grep -Ec "${component_upper}_ASSET=${asset_arm64} ${component_upper}_SHA256=${arm64_sha256}" "${updated_dockerfile}")" == 1 ]] || exit 1
if [[ "${component}" == codex ]]; then
  grep -Eq "^Includes pinned Codex \`${version}\`," "${updated_readme}" || exit 1
  [[ "$(grep -Ec "^Includes pinned Codex \`${version}\`," "${updated_readme}")" == 1 ]] || exit 1
else
  grep -Eq "^- OpenCode \`${version}\`\$" "${updated_readme}" || exit 1
  [[ "$(grep -Ec "^- OpenCode \`${version}\`\$" "${updated_readme}")" == 1 ]] || exit 1
fi

# Prepare and validate both files before replacing either source file.
mv -- "${updated_dockerfile}" "${dockerfile}"
mv -- "${updated_readme}" "${readme}"
echo "Updated ${component} from ${current_version} to ${version}"
output changed true; common_outputs
