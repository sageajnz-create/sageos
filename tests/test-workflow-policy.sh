#!/usr/bin/env bash
# Offline policy checks for security-sensitive GitHub Actions configuration.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
workflows="${repo_root}/.github/workflows"
build="${workflows}/build.yml"
build_disk="${workflows}/build-disk.yml"
justfile="${repo_root}/Justfile"

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
# bootc-image-builder runs bootc inside its own container, so it needs the same
# policy and public key mounted at the paths referenced by that policy. Keep the
# workflow and local recipe aligned so both paths verify the source image.
for build_entrypoint in "${build_disk}" "${justfile}"; do
    grep -Fq '${POLICY_FILE}:/etc/containers/policy.json:ro' "${build_entrypoint}" \
        || fail "${build_entrypoint#"${repo_root}/"} does not mount the signature policy into the disk builder"
    grep -Fq '${PUBLIC_KEY}:/etc/pki/containers/cosign.pub:ro' "${build_entrypoint}" \
        || fail "${build_entrypoint#"${repo_root}/"} does not mount the signature key into the disk builder"
done
if grep -Fq 'osbuild/bootc-image-builder-action@' "${build_disk}"; then
    fail "disk workflow uses the action that cannot mount the signature policy"
fi
grep -Fq 'output-directory=${PWD}/output' "${build_disk}" \
    || fail "disk workflow does not preserve the output-directory contract"
grep -Fq 'gh attestation verify "oci://${IMAGE_REF}"' "${build_disk}" \
    || fail "disk workflow does not verify published image provenance before building"
grep -Fq -- '--signer-workflow "${GITHUB_REPOSITORY}/.github/workflows/build.yml"' "${build_disk}" \
    || fail "disk workflow does not restrict provenance to the release workflow"
grep -Fq -- '--source-ref refs/heads/main' "${build_disk}" \
    || fail "disk workflow accepts provenance from a non-main source ref"
grep -Fq 'BUILD_CONTAINER_ARGS=(--build-container "${BIB_BUILD_IMAGE}")' "${build_disk}" \
    || fail "disk workflow does not isolate the nested build root from the source image policy"
grep -Fq 'BUILD_CONTAINER_ARGS=(--build-container "{{ bib_build_image }}")' "${justfile}" \
    || fail "local disk builds do not use the clean nested build root"
grep -Fq 'if [[ "${DISK_TYPE}" == "qcow2" ]]' "${build_disk}" \
    || fail "clean build root is not scoped to QCOW2"
buildroot="${repo_root}/disk_config/Containerfile.buildroot"
grep -Fq 'FROM quay.io/fedora/fedora-bootc:42' "${buildroot}" \
    || fail "QCOW2 build root does not match the Bazzite Fedora generation"
grep -Fq 'dnf install -y btrfs-progs' "${buildroot}" \
    || fail "QCOW2 build root does not provide mkfs.btrfs"
grep -Fq 'COPY system_files/etc/containers/policy.json /etc/containers/policy.json' "${buildroot}" \
    || fail "QCOW2 build root does not include the SageOS signature policy"
grep -Fq 'COPY system_files/etc/pki/containers/cosign.pub /etc/pki/containers/cosign.pub' "${buildroot}" \
    || fail "QCOW2 build root does not include the Cosign public key"
grep -Fq -- '--file disk_config/Containerfile.buildroot' "${build_disk}" \
    && grep -A2 -- '--file disk_config/Containerfile.buildroot' "${build_disk}" | grep -Eq '^[[:space:]]+\.$' \
    || fail "disk workflow does not build the nested root from the repository root"
grep -Fq -- '--file disk_config/Containerfile.buildroot' "${justfile}" \
    && grep -A2 -- '--file disk_config/Containerfile.buildroot' "${justfile}" | grep -Eq '^[[:space:]]+\.$' \
    || fail "local disk builds do not build the nested root from the repository root"
validator="${repo_root}/scripts/validate-qcow2.exp"
grep -Fq 'set login_timeout 1800' "${validator}" \
    || fail "VM validator does not allow the first-boot provisioning reboot to finish"
if grep -Fq -- '-no-reboot' "${validator}"; then
    fail "VM validator exits during the expected first-boot provisioning reboot"
fi
grep -Fq 'signal=off' "${validator}" \
    || fail "VM validator lets the serial PTY hang up during the first-boot reboot"
grep -Fq 'OVMF_VARS' "${validator}" \
    || fail "VM validator does not persist UEFI variables across the first-boot reboot"
grep -Fq '/tmp/sageos-doctor-ci' "${validator}" \
    || fail "VM validator does not run this checkout's doctor inside the guest"
grep -Fq '/tmp/sageos-policy-ci.json' "${validator}" \
    || fail "VM validator does not install this checkout's signature policy into the guest"
grep -Fq '__SAGEOS_POLICY_READY__' "${validator}" \
    || fail "VM validator does not deploy the image signature policy into /etc before doctor"
grep -Fq {^[A-Za-z0-9+/]{76}$} "${validator}" \
    || fail "VM validator does not drop kernel serial noise from the journal dump"
if grep -Fq "< '\$serial_log'" "${validator}"; then
    fail "VM validator still opens the serial log through a quoted shell redirect"
fi
grep -Fq 'WARN: serial journal dump was not valid base64' "${justfile}" \
    || fail "local VM validation fails the gate when the serial journal dump is noisy"
doctor="${repo_root}/system_files/usr/libexec/sageos-doctor"
pin="${repo_root}/system_files/usr/libexec/sageos-pin"
if grep -Fq 'export SAGEOS_DOCTOR_STATUS=' "${doctor}"; then
    fail "doctor puts rpm-ostree JSON in the environment"
fi
if grep -Fq 'export SAGEOS_PIN_STATUS=' "${pin}"; then
    fail "pin puts rpm-ostree JSON in the environment"
fi
grep -Fq 'python3 - "${status_file}"' "${doctor}" \
    || fail "doctor does not pass rpm-ostree status through a file"
grep -Fq 'python3 - "${status_file}"' "${pin}" \
    || fail "pin does not pass rpm-ostree status through a file"
grep -Fq 'sudo chmod 0666 /dev/kvm' "${build_disk}" \
    || fail "disk workflow does not enable KVM acceleration for the VM gate"
# The nightly VM check must consume the image from a completed scheduled build,
# not race image publication on an unrelated cron timer.
grep -Fq 'workflow_run:' "${build_disk}" \
    || fail "disk workflow does not follow the container build"
grep -Fq 'github.event.workflow_run.conclusion == '\''success'\''' "${build_disk}" \
    || fail "disk workflow can run after a failed container build"
grep -Fq 'github.event.workflow_run.event == '\''schedule'\''' "${build_disk}" \
    || fail "disk workflow is not restricted to the nightly container build"
grep -Fq 'github.event.workflow_run.head_branch == github.event.repository.default_branch' "${build_disk}" \
    || fail "disk workflow can validate an image from a non-default branch"
grep -A8 -F 'workflow_run:' "${build_disk}" | grep -Fq -- '- main' \
    || fail "disk workflow trigger is not filtered to main"
if grep -Fq 'cron:' "${build_disk}"; then
    fail "disk workflow has an independent schedule and can race image publication"
fi
if grep -Eq -- "-[[:space:]]*['\"]?\./" "${build_disk}"; then
    fail "disk workflow path filters use ./ prefixes that GitHub does not match"
fi
# The literal GitHub expression is the policy target, not a shell expansion.
# shellcheck disable=SC2016
grep -Fq 'subject-digest: ${{ steps.push-image.outputs.digest }}' "${build}" \
    || fail "provenance is not bound to the pushed image digest"
grep -Fq 'push-to-registry: true' "${build}" || fail "provenance is not published with the image"

echo "workflow policy PASS: durable builds, chained VM gate, bounded SBOM, scan, and digest provenance"
