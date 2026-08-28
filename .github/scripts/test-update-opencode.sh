#!/usr/bin/env bash
set -euo pipefail

repository_root="$(git rev-parse --show-toplevel)"
temporary_directory="$(mktemp -d)"
trap 'rm -rf "${temporary_directory}"' EXIT
mkdir -p "${temporary_directory}/golang"
cp "${repository_root}/golang/Dockerfile" "${temporary_directory}/golang/Dockerfile"
cp "${repository_root}/golang/README.md" "${temporary_directory}/golang/README.md"
current_version="$(sed -nE 's/^ARG OPENCODE_VERSION=([^[:space:]]+)$/\1/p' "${repository_root}/golang/Dockerfile")"
simulated_version="999.0.0"

UPDATE_OPENCODE_VERSION="${current_version}" \
UPDATE_OPENCODE_AMD64_SHA256=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa \
UPDATE_OPENCODE_ARM64_SHA256=bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb \
REPOSITORY_ROOT="${temporary_directory}" bash "${repository_root}/.github/scripts/update-opencode.sh"
cmp "${repository_root}/golang/Dockerfile" "${temporary_directory}/golang/Dockerfile"
cmp "${repository_root}/golang/README.md" "${temporary_directory}/golang/README.md"

UPDATE_OPENCODE_VERSION="${simulated_version}" \
UPDATE_OPENCODE_AMD64_SHA256=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa \
UPDATE_OPENCODE_ARM64_SHA256=bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb \
REPOSITORY_ROOT="${temporary_directory}" bash "${repository_root}/.github/scripts/update-opencode.sh"

grep -qx "ARG OPENCODE_VERSION=${simulated_version}" "${temporary_directory}/golang/Dockerfile"
grep -q 'OPENCODE_SHA256=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa' "${temporary_directory}/golang/Dockerfile"
grep -q 'OPENCODE_SHA256=bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb' "${temporary_directory}/golang/Dockerfile"
grep -qx -- "- OpenCode \`${simulated_version}\`" "${temporary_directory}/golang/README.md"
