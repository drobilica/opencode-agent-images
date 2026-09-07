#!/usr/bin/env bash
set -euo pipefail

root="$(git rev-parse --show-toplevel)"
updater="${root}/.github/scripts/update-dependency.sh"
fixture_codex="${root}/.github/scripts/fixtures/releases.json"
fixture_opencode="${root}/.github/scripts/fixtures/opencode-releases.json"
work="$(mktemp -d)"
trap 'rm -rf "${work}"' EXIT

copy_component() {
  local destination="$1"
  mkdir -p "${destination}/codex-generic-dev" "${destination}/opencode-v1-golang-dev"
  cp "${root}/codex-generic-dev/Dockerfile" "${destination}/codex-generic-dev/Dockerfile"
  cp "${root}/codex-generic-dev/README.md" "${destination}/codex-generic-dev/README.md"
  cp "${root}/opencode-v1-golang-dev/Dockerfile" "${destination}/opencode-v1-golang-dev/Dockerfile"
  cp "${root}/opencode-v1-golang-dev/README.md" "${destination}/opencode-v1-golang-dev/README.md"

  # Keep test inputs independent of the versions currently pinned by the
  # repository, including when this suite runs on an automated update PR.
  sed -E 's/^ARG CODEX_VERSION=.*/ARG CODEX_VERSION=0.151.0/' \
    "${destination}/codex-generic-dev/Dockerfile" >"${destination}/codex-generic-dev/Dockerfile.tmp"
  mv "${destination}/codex-generic-dev/Dockerfile.tmp" "${destination}/codex-generic-dev/Dockerfile"
  sed -E \
    -e 's/^Includes pinned Codex `[0-9]+\.[0-9]+\.[0-9]+`,/Includes pinned Codex `0.151.0`,/' \
    -e 's|^docker pull ghcr.io/drobilica/codex-generic-dev:[0-9]+\.[0-9]+\.[0-9]+$|docker pull ghcr.io/drobilica/codex-generic-dev:0.151.0|' \
    "${destination}/codex-generic-dev/README.md" >"${destination}/codex-generic-dev/README.md.tmp"
  mv "${destination}/codex-generic-dev/README.md.tmp" "${destination}/codex-generic-dev/README.md"
  sed -E 's/^ARG OPENCODE_VERSION=.*/ARG OPENCODE_VERSION=1.18.25/' \
    "${destination}/opencode-v1-golang-dev/Dockerfile" >"${destination}/opencode-v1-golang-dev/Dockerfile.tmp"
  mv "${destination}/opencode-v1-golang-dev/Dockerfile.tmp" "${destination}/opencode-v1-golang-dev/Dockerfile"
  sed -E \
    -e 's/^- OpenCode `[0-9]+\.[0-9]+\.[0-9]+`$/- OpenCode `1.18.25`/' \
    -e 's|^docker pull ghcr.io/drobilica/opencode-v1-golang-dev:[0-9]+\.[0-9]+\.[0-9]+$|docker pull ghcr.io/drobilica/opencode-v1-golang-dev:1.18.25|' \
    "${destination}/opencode-v1-golang-dev/README.md" >"${destination}/opencode-v1-golang-dev/README.md.tmp"
  mv "${destination}/opencode-v1-golang-dev/README.md.tmp" "${destination}/opencode-v1-golang-dev/README.md"
  printf 'sentinel\n' >"${destination}/unrelated.txt"
}
run_update() {
  local component="$1" fixture="$2" destination="$3"
  RELEASES_FIXTURE="${fixture}" REPOSITORY_ROOT="${destination}" GITHUB_OUTPUT="${destination}/output" \
    bash "${updater}" "${component}"
}
expect_failure_without_edits() {
  local component="$1" fixture="$2" name="$3" dockerfile_path="$4" readme_path="$5"
  local destination="${work}/${name}"
  copy_component "${destination}"
  cp "${destination}/${dockerfile_path}" "${destination}/before-dockerfile"
  cp "${destination}/${readme_path}" "${destination}/before-readme"
  if run_update "${component}" "${fixture}" "${destination}" >/dev/null 2>&1; then
    echo "Expected ${name} to fail" >&2
    exit 1
  fi
  cmp "${destination}/before-dockerfile" "${destination}/${dockerfile_path}"
  cmp "${destination}/before-readme" "${destination}/${readme_path}"
}

# Codex stable update: exact rust-v tags, highest stable only, and both digests.
codex_new="${work}/codex-new"; copy_component "${codex_new}"
cp "${codex_new}/opencode-v1-golang-dev/Dockerfile" "${work}/codex-before-opencode-Dockerfile"
cp "${codex_new}/opencode-v1-golang-dev/README.md" "${work}/codex-before-opencode-README.md"
run_update codex "${fixture_codex}" "${codex_new}"
grep -qx 'ARG CODEX_VERSION=0.152.0' "${codex_new}/codex-generic-dev/Dockerfile"
grep -q 'CODEX_SHA256=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa' "${codex_new}/codex-generic-dev/Dockerfile"
grep -q 'CODEX_SHA256=bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb' "${codex_new}/codex-generic-dev/Dockerfile"
grep -q 'Includes pinned Codex `0.152.0`' "${codex_new}/codex-generic-dev/README.md"
grep -qx 'docker pull ghcr.io/drobilica/codex-generic-dev:0.152.0' "${codex_new}/codex-generic-dev/README.md"
cmp "${work}/codex-before-opencode-Dockerfile" "${codex_new}/opencode-v1-golang-dev/Dockerfile"
cmp "${work}/codex-before-opencode-README.md" "${codex_new}/opencode-v1-golang-dev/README.md"
grep -qx 'sentinel' "${codex_new}/unrelated.txt"
grep -q '^changed=true$' "${codex_new}/output"

# Equal version is a no-op and emits changed=false.
codex_equal_fixture="${work}/codex-equal.json"
jq '[.[] | select(.tag_name == "rust-v0.151.0")]' "${fixture_codex}" >"${codex_equal_fixture}"
codex_equal="${work}/codex-equal"; copy_component "${codex_equal}"
before_equal="${work}/before-equal"; cp -R "${codex_equal}" "${before_equal}"
run_update codex "${codex_equal_fixture}" "${codex_equal}" >/dev/null
cmp "${before_equal}/codex-generic-dev/Dockerfile" "${codex_equal}/codex-generic-dev/Dockerfile"
cmp "${before_equal}/codex-generic-dev/README.md" "${codex_equal}/codex-generic-dev/README.md"
grep -qx 'changed=false' "${codex_equal}/output"

# A syntactically hostile or merely non-canonical tag is never a candidate,
# even when upstream metadata does not mark it as a prerelease.
unsafe_tag_fixture="${work}/unsafe-tag.json"
jq '[.[] | select(.tag_name == "rust-v0.152.0") | .tag_name = "rust-v9.9.9;echo-unsafe"]' "${fixture_codex}" >"${unsafe_tag_fixture}"
expect_failure_without_edits codex "${unsafe_tag_fixture}" unsafe-tag codex-generic-dev/Dockerfile codex-generic-dev/README.md

# Invalid response, no stable release, and missing digest fail without edits.
invalid_fixture="${work}/invalid.json"; jq '.[0]' "${fixture_codex}" >"${invalid_fixture}"
expect_failure_without_edits codex "${invalid_fixture}" invalid codex-generic-dev/Dockerfile codex-generic-dev/README.md
nostable_fixture="${work}/nostable.json"; jq 'map(.prerelease = true)' "${fixture_codex}" >"${nostable_fixture}"
expect_failure_without_edits codex "${nostable_fixture}" nostable codex-generic-dev/Dockerfile codex-generic-dev/README.md
missing_digest_fixture="${work}/missing-digest.json"; jq 'map(if .tag_name == "rust-v0.152.0" then .assets[0].digest = null else . end)' "${fixture_codex}" >"${missing_digest_fixture}"
expect_failure_without_edits codex "${missing_digest_fixture}" missing-digest codex-generic-dev/Dockerfile codex-generic-dev/README.md
downgrade_fixture="${work}/downgrade.json"; jq '[.[] | select(.tag_name == "rust-v0.152.0") | .tag_name = "rust-v0.150.0"]' "${fixture_codex}" >"${downgrade_fixture}"
downgrade="${work}/downgrade"; copy_component "${downgrade}"
before_downgrade="${work}/before-downgrade"; cp -R "${downgrade}" "${before_downgrade}"
run_update codex "${downgrade_fixture}" "${downgrade}" >/dev/null
cmp "${before_downgrade}/codex-generic-dev/Dockerfile" "${downgrade}/codex-generic-dev/Dockerfile"
cmp "${before_downgrade}/codex-generic-dev/README.md" "${downgrade}/codex-generic-dev/README.md"
grep -qx 'changed=false' "${downgrade}/output"

# OpenCode uses the vX.Y.Z tag convention and updates only its own files.
opencode_new="${work}/opencode-new"; copy_component "${opencode_new}"
cp "${opencode_new}/codex-generic-dev/Dockerfile" "${work}/opencode-before-codex-Dockerfile"
cp "${opencode_new}/codex-generic-dev/README.md" "${work}/opencode-before-codex-README.md"
run_update opencode "${fixture_opencode}" "${opencode_new}"
grep -qx 'ARG OPENCODE_VERSION=1.18.26' "${opencode_new}/opencode-v1-golang-dev/Dockerfile"
grep -q 'OPENCODE_SHA256=cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc' "${opencode_new}/opencode-v1-golang-dev/Dockerfile"
grep -q 'OPENCODE_SHA256=dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd' "${opencode_new}/opencode-v1-golang-dev/Dockerfile"
grep -qx -- '- OpenCode `1.18.26`' "${opencode_new}/opencode-v1-golang-dev/README.md"
grep -qx 'docker pull ghcr.io/drobilica/opencode-v1-golang-dev:1.18.26' "${opencode_new}/opencode-v1-golang-dev/README.md"
cmp "${work}/opencode-before-codex-Dockerfile" "${opencode_new}/codex-generic-dev/Dockerfile"
cmp "${work}/opencode-before-codex-README.md" "${opencode_new}/codex-generic-dev/README.md"
grep -qx 'sentinel' "${opencode_new}/unrelated.txt"

# OpenCode equality is independently idempotent.
opencode_equal_fixture="${work}/opencode-equal.json"
jq '[.[] | select(.tag_name == "v1.18.25")]' "${fixture_opencode}" >"${opencode_equal_fixture}"
opencode_equal="${work}/opencode-equal"; copy_component "${opencode_equal}"
cp "${opencode_equal}/opencode-v1-golang-dev/Dockerfile" "${work}/opencode-equal-Dockerfile"
cp "${opencode_equal}/opencode-v1-golang-dev/README.md" "${work}/opencode-equal-README.md"
run_update opencode "${opencode_equal_fixture}" "${opencode_equal}" >/dev/null
cmp "${work}/opencode-equal-Dockerfile" "${opencode_equal}/opencode-v1-golang-dev/Dockerfile"
cmp "${work}/opencode-equal-README.md" "${opencode_equal}/opencode-v1-golang-dev/README.md"
grep -qx 'changed=false' "${opencode_equal}/output"

# The workflow's fixed branch and open-PR lookup are deterministic duplicate prevention.
grep -q 'automation/update-${{ matrix.component }}' "${root}/.github/workflows/update-dependencies.yml"
grep -q 'gh pr list --state open --head "${BRANCH}"' "${root}/.github/workflows/update-dependencies.yml"
grep -q 'gh pr edit "${pr_number}"' "${root}/.github/workflows/update-dependencies.yml"
grep -q 'Automated daily dependency update' "${root}/.github/workflows/update-dependencies.yml"

# Automation validation dispatches the actual remote branch HEAD and selects
# only the image workflow affected by the dependency update.
workflow="${root}/.github/workflows/update-dependencies.yml"
grep -q '^  actions: write$' "${workflow}"
grep -q 'validation_workflow=codex-generic-dev.yml' "${workflow}"
grep -q 'validation_workflow=opencode-v1-golang-dev.yml' "${workflow}"
grep -q 'git ls-remote origin "refs/heads/${BRANCH}"' "${workflow}"
grep -q 'gh workflow run "${validation_workflow}" --ref "${BRANCH}"' "${workflow}"
grep -q 'expected_sha=${validation_sha}' "${workflow}"
grep -q 'force-with-lease="refs/heads/${BRANCH}:${remote_sha}"' "${workflow}"
grep -q 'gh pr create --base "${DEFAULT_BRANCH}" --head "${BRANCH}"' "${workflow}"
grep -q 'gh pr edit "${pr_number}"' "${workflow}"
! grep -q 'pull_request_target\|statuses: write\|checks: write' "${workflow}"

for image_workflow in codex-generic-dev.yml opencode-v1-golang-dev.yml opencode-v2-golang-dev.yml; do
  image_workflow_path="${root}/.github/workflows/${image_workflow}"
  grep -q '^  pull_request:$' "${image_workflow_path}"
  grep -q '^  workflow_dispatch:$' "${image_workflow_path}"
  grep -q 'required: true' "${image_workflow_path}"
  grep -q 'expected_sha:.*inputs.expected_sha' "${image_workflow_path}"
  grep -q 'uses: ./.github/workflows/reusable-image-release.yml' "${image_workflow_path}"
  grep -q '^  push:$' "${image_workflow_path}"
done
reusable="${root}/.github/workflows/reusable-image-release.yml"
grep -q 'test "${GITHUB_SHA}" = "${EXPECTED_SHA}"' "${reusable}"
grep -q 'ref:.*inputs.expected_sha.*github.sha' "${reusable}"
grep -q 'branches: \[main\]' "${root}/.github/workflows/codex-generic-dev.yml"
grep -q 'tags: \["codex-generic-dev-v\*\.\*\.\*"\]' "${root}/.github/workflows/codex-generic-dev.yml"
grep -q 'branches: \[main\]' "${root}/.github/workflows/opencode-v1-golang-dev.yml"
grep -q 'tags: \["opencode-v1-golang-dev-v\*\.\*\.\*"\]' "${root}/.github/workflows/opencode-v1-golang-dev.yml"

# Family metadata resolves the pinned agent version and rejects unrelated or
# generic repository tags before any publication can occur.
for family in opencode-v1-golang-dev opencode-v2-golang-dev codex-generic-dev; do
  metadata="$(bash "${root}/.github/scripts/image-metadata.sh" "${family}")"
  version="$(sed -n 's/^agent_version=//p' <<<"${metadata}")"
  prefix="$(sed -n 's/^release_tag_prefix=//p' <<<"${metadata}")"
  bash "${root}/.github/scripts/image-metadata.sh" "${family}" "${prefix}${version}" >/dev/null
  if bash "${root}/.github/scripts/image-metadata.sh" "${family}" v0.1.4 >/dev/null 2>&1; then
    echo "Generic repository tag unexpectedly accepted for ${family}" >&2
    exit 1
  fi
done
echo "dependency updater tests passed"
