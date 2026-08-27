#!/usr/bin/env bash
# Offline policy checks for security-sensitive GitHub Actions configuration.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
workflows="${repo_root}/.github/workflows"
build="${workflows}/build.yml"

fail() {
    echo "FAIL: $*" >&2
    exit 1
}

# Every external action must be immutable. Version comments remain available
# to Renovate and humans, while execution is locked to a full commit SHA.
while IFS= read -r action; do
    [[ "${action}" =~ ^[^@[:space:]]+@[0-9a-f]{40}$ ]] \
        || fail "GitHub Action is not pinned to a full commit SHA: ${action}"
done < <(sed -n 's/^[[:space:]]*uses:[[:space:]]*\([^[:space:]#]*\).*/\1/p' "${workflows}"/*.yml)

grep -Fq 'attestations: write' "${build}" || fail "workflow cannot publish provenance"
grep -Fq 'format: spdx-json' "${build}" || fail "SPDX JSON SBOM generation missing"
grep -Fq 'sbom: sageos.spdx.json' "${build}" || fail "vulnerability scan does not consume the generated SBOM"
grep -Fq 'fail-build: false' "${build}" || fail "scan mode changed without updating the baseline policy test"
# The literal GitHub expression is the policy target, not a shell expansion.
# shellcheck disable=SC2016
grep -Fq 'subject-digest: ${{ steps.push-image.outputs.digest }}' "${build}" \
    || fail "provenance is not bound to the pushed image digest"
grep -Fq 'push-to-registry: true' "${build}" || fail "provenance is not published with the image"

echo "workflow policy PASS: pinned actions, SBOM, scan, and digest provenance"
