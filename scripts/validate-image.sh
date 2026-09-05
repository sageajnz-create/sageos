#!/usr/bin/env bash
# Assert contracts against an assembled SageOS OCI image.
set -euo pipefail

if [[ "$#" -ne 1 ]]; then
    echo "usage: validate-image.sh IMAGE" >&2
    exit 2
fi

image="$1"
runtime=()
if podman image exists "${image}" 2>/dev/null; then
    runtime=(podman)
elif command -v sudo >/dev/null && sudo podman image exists "${image}" 2>/dev/null; then
    runtime=(sudo podman)
else
    echo "image not found in rootless or rootful Podman storage: ${image}" >&2
    exit 1
fi

"${runtime[@]}" run --rm --entrypoint /usr/bin/bash "${image}" -s <<'IMAGE_TEST'
set -euo pipefail

fail() {
    echo "FAIL: $*" >&2
    exit 1
}

for package in gamemode glx-utils libva-utils tmux vulkan-tools; do
    rpm -q "${package}" >/dev/null || fail "required package missing: ${package}"
done

for executable in sageos-doctor sageos-flatpak-setup sageos-pin; do
    [[ -x "/usr/libexec/${executable}" ]] || fail "missing executable: ${executable}"
done

for unit in podman.socket sageos-flatpak-setup.service sageos-pin.service; do
    systemctl is-enabled "${unit}" >/dev/null || fail "unit not enabled: ${unit}"
done

# Signing trio must be live under /etc (not only in the build context overlay).
[[ -f /etc/containers/policy.json ]] || fail "missing /etc/containers/policy.json"
[[ -f /etc/pki/containers/cosign.pub ]] || fail "missing /etc/pki/containers/cosign.pub"
[[ -f /etc/containers/registries.d/ghcr.io-sageajnz-create-sageos.yaml ]] \
    || fail "missing /etc/containers/registries.d/ghcr.io-sageajnz-create-sageos.yaml"
grep -Fq 'ghcr.io/sageajnz-create/sageos:' \
    /etc/containers/registries.d/ghcr.io-sageajnz-create-sageos.yaml \
    || fail "registries.d is not scoped to the SageOS repository"
grep -Fq 'use-sigstore-attachments: true' \
    /etc/containers/registries.d/ghcr.io-sageajnz-create-sageos.yaml \
    || fail "registries.d does not enable sigstore attachments"
key_sha256="$(sha256sum /etc/pki/containers/cosign.pub | awk '{print $1}')"
[[ "${key_sha256}" == "293b458eb7a2dda8f80c5e27bc81e73ef4018c0591abb114e5dde6816e149914" ]] \
    || fail "assembled cosign.pub sha256 is ${key_sha256}, expected SageOS key"
python3 - <<'PYEOF'
import json
from pathlib import Path

policy = json.loads(Path("/etc/containers/policy.json").read_text())
rules = policy["transports"]["docker"]["ghcr.io/sageajnz-create/sageos"]
expected_key = "/etc/pki/containers/cosign.pub"
if not any(
    rule.get("type") == "sigstoreSigned" and rule.get("keyPath") == expected_key
    for rule in rules
):
    raise SystemExit("FAIL: assembled image does not enforce SageOS signatures")
PYEOF

grep -Fqx 'import "/usr/share/ublue-os/just/70-sageos.just"' /usr/share/ublue-os/justfile \
    || fail "SageOS ujust import missing from assembled image"
grep -Fq 'PRETTY_NAME="SageOS 0.1 (built on Bazzite)"' /usr/lib/os-release \
    || fail "SageOS branding missing from assembled image"
grep -Fq 'NAME=SageOS' /etc/sageos-release || fail "SageOS release identity missing"

echo "assembled image PASS: packages, modes, services, signing trio, ujust, and identity"
IMAGE_TEST
