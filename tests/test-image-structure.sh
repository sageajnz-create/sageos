#!/usr/bin/env bash
# Offline assertions for files that are copied into the SageOS image.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SYSTEM_ROOT="${REPO_ROOT}/system_files"

fail() {
    echo "FAIL: $*" >&2
    exit 1
}

assert_file() {
    [[ -f "${SYSTEM_ROOT}$1" ]] || fail "missing image file: $1"
}

assert_executable() {
    assert_file "$1"
    [[ -x "${SYSTEM_ROOT}$1" ]] || fail "image executable lacks execute bit: $1"
}

assert_contains() {
    local file="$1" pattern="$2"
    grep -Fq -- "${pattern}" "${file}" || fail "${file#"${REPO_ROOT}/"} does not contain: ${pattern}"
}

for executable in \
    /usr/libexec/sageos-doctor \
    /usr/libexec/sageos-flatpak-setup \
    /usr/libexec/sageos-pin; do
    assert_executable "${executable}"
done

for unit in sageos-flatpak-setup.service sageos-pin.service; do
    unit_file="${SYSTEM_ROOT}/usr/lib/systemd/system/${unit}"
    assert_file "/usr/lib/systemd/system/${unit}"
    exec_start="$(sed -n 's/^ExecStart=//p' "${unit_file}")"
    [[ -n "${exec_start}" ]] || fail "${unit} has no ExecStart"
    assert_executable "${exec_start%% *}"
    assert_contains "${REPO_ROOT}/build_files/scripts.d/30-services.sh" "systemctl enable ${unit}"
done

policy="${SYSTEM_ROOT}/etc/containers/policy.json"
key="${SYSTEM_ROOT}/etc/pki/containers/cosign.pub"
registries_d="${SYSTEM_ROOT}/etc/containers/registries.d/ghcr.io-sageajnz-create-sageos.yaml"
expected_key_sha256="293b458eb7a2dda8f80c5e27bc81e73ef4018c0591abb114e5dde6816e149914"
assert_file /etc/containers/policy.json
assert_file /etc/pki/containers/cosign.pub
assert_file /etc/containers/registries.d/ghcr.io-sageajnz-create-sageos.yaml
[[ ! -e "${SYSTEM_ROOT}/usr/etc" ]] \
    || fail "container image must use /etc; /usr/etc is reserved for bootc internals"
cmp -s "${REPO_ROOT}/cosign.pub" "${key}" \
    || fail "repository and image cosign public keys differ"
# Offline structure test inspects system_files (the overlay source). build.sh
# copies that tree onto the image root (`cp -avf /ctx/system_files/. /`), so
# these paths become live /etc paths in the assembled image; validate-image.sh
# asserts the assembled copy.
assert_contains "${registries_d}" "ghcr.io/sageajnz-create/sageos:"
assert_contains "${registries_d}" "use-sigstore-attachments: true"
grep -Eq '^[[:space:]]*default-docker:' "${registries_d}" \
    && fail "registries.d must not enable default-docker"
grep -Eq '^[[:space:]]*ghcr\.io:' "${registries_d}" \
    && fail "registries.d must not enable whole ghcr.io"
key_sha256="$(sha256sum "${key}" | awk '{print $1}')"
[[ "${key_sha256}" == "${expected_key_sha256}" ]] \
    || fail "image cosign.pub sha256 is ${key_sha256}, expected ${expected_key_sha256}"
python3 - "${policy}" "${key}" <<'PYEOF'
import json
import pathlib
import sys

policy_path, key_path = map(pathlib.Path, sys.argv[1:])
try:
    policy = json.loads(policy_path.read_text())
except (OSError, json.JSONDecodeError) as exc:
    raise SystemExit(f"FAIL: invalid containers policy: {exc}")

rules = policy.get("transports", {}).get("docker", {}).get(
    "ghcr.io/sageajnz-create/sageos", []
)
expected_key = "/etc/pki/containers/cosign.pub"
if not any(rule.get("type") == "sigstoreSigned" and rule.get("keyPath") == expected_key
           for rule in rules):
    raise SystemExit("FAIL: SageOS registry path is not protected by the committed key")
if not key_path.read_text().strip():
    raise SystemExit("FAIL: cosign public key is empty")
PYEOF

flatpaks="${SYSTEM_ROOT}/usr/share/sageos/flatpaks.list"
assert_file /usr/share/sageos/flatpaks.list
mapfile -t app_ids < <(sed -E '/^[[:space:]]*(#|$)/d' "${flatpaks}")
[[ "${#app_ids[@]}" -gt 0 ]] || fail "flatpaks.list has no applications"
[[ "$(printf '%s\n' "${app_ids[@]}" | sort -u | wc -l)" -eq "${#app_ids[@]}" ]] \
    || fail "flatpaks.list contains duplicate applications"
for app_id in "${app_ids[@]}"; do
    [[ "${app_id}" =~ ^[A-Za-z0-9_-]+(\.[A-Za-z0-9_-]+){2,}$ ]] \
        || fail "invalid Flatpak application ID: ${app_id}"
done

just_stage="${REPO_ROOT}/build_files/scripts.d/40-just.sh"
just_recipes="${SYSTEM_ROOT}/usr/share/ublue-os/just/70-sageos.just"
assert_file /usr/share/ublue-os/just/70-sageos.just
assert_contains "${just_stage}" 'import "/usr/share/ublue-os/just/70-sageos.just"'
for recipe in sageos-doctor sageos-version sageos-update sageos-rollback; do
    assert_contains "${just_recipes}" "${recipe}:"
done

echo "image structure PASS: executables, units, signing trio, Flatpaks, and ujust wiring"
