#!/usr/bin/env bash
# Update the OpenCode version and Linux asset checksums together.
set -euo pipefail

repository_root="${REPOSITORY_ROOT:-$(git rev-parse --show-toplevel)}"
dockerfile="${repository_root}/golang/Dockerfile"
readme="${repository_root}/golang/README.md"

current_version="$(sed -nE 's/^ARG OPENCODE_VERSION=([^[:space:]]+)$/\1/p' "${dockerfile}")"

if [[ -z "${current_version}" ]]; then
    echo "Could not read OPENCODE_VERSION from ${dockerfile}" >&2
    exit 1
fi

if [[ -n "${UPDATE_OPENCODE_VERSION:-}" ]]; then
    version="${UPDATE_OPENCODE_VERSION}"
    amd64_sha256="${UPDATE_OPENCODE_AMD64_SHA256:?UPDATE_OPENCODE_AMD64_SHA256 is required with UPDATE_OPENCODE_VERSION}"
    arm64_sha256="${UPDATE_OPENCODE_ARM64_SHA256:?UPDATE_OPENCODE_ARM64_SHA256 is required with UPDATE_OPENCODE_VERSION}"
else
    release="$({ gh api --method GET 'repos/anomalyco/opencode/releases?per_page=100' \
        | jq -ce '[.[] | select(.draft | not) | select(.prerelease | not)][0]'; })"
    version="$(jq -r '.tag_name | ltrimstr("v")' <<<"${release}")"

    if [[ "${version}" == "${current_version}" ]]; then
        echo "OpenCode ${version} is already pinned"
        exit 0
    fi

    amd64_url="$(jq -r '.assets[] | select(.name == "opencode-linux-x64-baseline.tar.gz") | .browser_download_url' <<<"${release}")"
    arm64_url="$(jq -r '.assets[] | select(.name == "opencode-linux-arm64.tar.gz") | .browser_download_url' <<<"${release}")"

    if [[ -z "${version}" || "${version}" == "null" || -z "${amd64_url}" || "${amd64_url}" == "null" || -z "${arm64_url}" || "${arm64_url}" == "null" ]]; then
        echo "Latest stable OpenCode release is missing an expected Linux asset" >&2
        exit 1
    fi

    temporary_directory="$(mktemp -d)"
    trap 'rm -rf "${temporary_directory}"' EXIT
    curl --fail --silent --show-error --location "${amd64_url}" --output "${temporary_directory}/opencode-linux-x64-baseline.tar.gz"
    curl --fail --silent --show-error --location "${arm64_url}" --output "${temporary_directory}/opencode-linux-arm64.tar.gz"
    amd64_sha256="$(sha256sum "${temporary_directory}/opencode-linux-x64-baseline.tar.gz" | awk '{print $1}')"
    arm64_sha256="$(sha256sum "${temporary_directory}/opencode-linux-arm64.tar.gz" | awk '{print $1}')"
fi

if [[ "${version}" == "${current_version}" ]]; then
    echo "OpenCode ${version} is already pinned"
    exit 0
fi

if [[ ! "${version}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ || ! "${amd64_sha256}" =~ ^[a-fA-F0-9]{64}$ || ! "${arm64_sha256}" =~ ^[a-fA-F0-9]{64}$ ]]; then
    echo "Invalid OpenCode version or SHA-256 checksum" >&2
    exit 1
fi

if [[ -z "${temporary_directory:-}" ]]; then
    temporary_directory="$(mktemp -d)"
    trap 'rm -rf "${temporary_directory}"' EXIT
fi
updated_dockerfile="${temporary_directory}/Dockerfile"
updated_readme="${temporary_directory}/README.md"

sed -E \
    -e "s|^ARG OPENCODE_VERSION=.*$|ARG OPENCODE_VERSION=${version}|" \
    -e "s|OPENCODE_ASSET=opencode-linux-x64-baseline.tar.gz OPENCODE_SHA256=[[:xdigit:]]{64}|OPENCODE_ASSET=opencode-linux-x64-baseline.tar.gz OPENCODE_SHA256=${amd64_sha256}|" \
    -e "s|OPENCODE_ASSET=opencode-linux-arm64.tar.gz OPENCODE_SHA256=[[:xdigit:]]{64}|OPENCODE_ASSET=opencode-linux-arm64.tar.gz OPENCODE_SHA256=${arm64_sha256}|" \
    "${dockerfile}" >"${updated_dockerfile}"
sed -E "s|^- OpenCode \`[0-9]+\.[0-9]+\.[0-9]+\`$|- OpenCode \`${version}\`|" "${readme}" >"${updated_readme}"

if [[ "$(grep -c "ARG OPENCODE_VERSION=${version}" "${updated_dockerfile}")" -ne 1 || "$(grep -c "OPENCODE_SHA256=${amd64_sha256}" "${updated_dockerfile}")" -ne 1 || "$(grep -c "OPENCODE_SHA256=${arm64_sha256}" "${updated_dockerfile}")" -ne 1 || "$(grep -c "OpenCode \`${version}\`" "${updated_readme}")" -ne 1 ]]; then
    echo "Refusing to write incomplete OpenCode update" >&2
    exit 1
fi

mv "${updated_dockerfile}" "${dockerfile}"
mv "${updated_readme}" "${readme}"
echo "Updated OpenCode from ${current_version} to ${version}"
