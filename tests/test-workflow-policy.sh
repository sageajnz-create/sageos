#!/usr/bin/env bash
# Offline policy checks for security-sensitive GitHub Actions configuration.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
workflows="${repo_root}/.github/workflows"
build="${workflows}/build.yml"
build_disk="${workflows}/build-disk.yml"

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
# GitHub expression is intentionally matched as literal workflow policy.
# shellcheck disable=SC2016
grep -Fq 'cancel-in-progress: ${{ github.event_name == '\''pull_request'\'' }}' "${build}" \
    || fail "expensive main builds can be cancelled by scheduled runs"
grep -Fq -- '--output spdx-json=sageos.spdx.json' "${build}" || fail "SPDX JSON SBOM generation missing"
# The image/tag variables must remain deferred to the Actions shell.
# shellcheck disable=SC2016
grep -Fq 'just validate-image "${IMAGE_NAME}:${DEFAULT_TAG}"' "${build}" \
    || fail "assembled image validation missing"
grep -Fq 'sbom: sageos.spdx.json' "${build}" || fail "vulnerability scan does not consume the generated SBOM"
grep -Fq 'fail-build: false' "${build}" || fail "scan mode changed without updating the baseline policy test"
grep -Fq 'needs: build_push' "${build}" || fail "supply-chain scan is not isolated from the build job"
# These are intentionally literal workflow-shell expressions.
# shellcheck disable=SC2016
grep -Fq 'sudo podman image mount "${image}"' "${build}" \
    || fail "SBOM does not mount the assembled local image"
# shellcheck disable=SC2016
grep -Fq '"dir:${mountpoint}"' "${build}" \
    || fail "SBOM does not scan the mounted image filesystem"
# shellcheck disable=SC2016
grep -Fq 'sudo podman image unmount "${image}"' "${build}" \
    || fail "SBOM image mount is not cleaned up"
grep -Fq -- '--override-default-catalogers rpm-db-cataloger' "${build}" \
    || fail "SBOM cataloger scope is not resource-bounded"
grep -Fq 'actions/download-artifact@3e5f45b2cfb9172054b4087a40e8e0b5a5461e7c' "${build}" \
    || fail "scan job does not consume the generated SBOM artifact"
if grep -Eq '(oci-archive:|podman:\$\{IMAGE_NAME\})' "${build}"; then
    fail "workflow recreates the oversized local OCI scan archive"
fi
if grep -Fq 'tee /etc/containers/policy.json' "${build_disk}"; then
    fail "disk workflow overrides container policy outside the bootc image"
fi
# The literal GitHub expression is the policy target, not a shell expansion.
# shellcheck disable=SC2016
grep -Fq 'subject-digest: ${{ steps.push-image.outputs.digest }}' "${build}" \
    || fail "provenance is not bound to the pushed image digest"
grep -Fq 'push-to-registry: true' "${build}" || fail "provenance is not published with the image"

echo "workflow policy PASS: durable builds, bounded SBOM, scan, and digest provenance"
