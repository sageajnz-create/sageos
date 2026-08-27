#!/usr/bin/env bash
# Offline behavior tests for the exact Flatpak provisioning script shipped in
# the image. A fake flatpak binary records calls and injects failures.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
script="${repo_root}/system_files/usr/libexec/sageos-flatpak-setup"
test_root="$(mktemp -d)"
trap 'rm -rf -- "${test_root}"' EXIT

mkdir -p "${test_root}/bin" "${test_root}/state"
flatpak_log="${test_root}/flatpak.log"
list="${test_root}/flatpaks.list"
version_file="${test_root}/state/flatpak_setup_version"

printf '%s\n' '# applications' 'com.example.First' '' 'org.example.Second' > "${list}"

ln -s "${repo_root}/tests/fixtures/flatpak" "${test_root}/bin/flatpak"

export PATH="${test_root}/bin:${PATH}"
export SAGEOS_TEST_FLATPAK_LOG="${flatpak_log}"
export SAGEOS_FLATPAK_LIST="${list}"
export SAGEOS_FLATPAK_VERSION_FILE="${version_file}"

expected_version="$(sha256sum "${list}" | cut -d' ' -f1)"

# A matching marker must make repeat boots a zero-work no-op.
printf '%s\n' "${expected_version}" > "${version_file}"
"${script}" >/dev/null
[[ ! -e "${flatpak_log}" ]] || { echo "FAIL: current list invoked flatpak" >&2; exit 1; }

# A changed list installs every real entry and records the hash only on success.
rm "${version_file}"
"${script}" >/dev/null
[[ "$(cat "${version_file}")" == "${expected_version}" ]] \
    || { echo "FAIL: successful run did not record list version" >&2; exit 1; }
grep -Fq -- 'install --system --noninteractive --or-update flathub com.example.First' "${flatpak_log}"
grep -Fq -- 'install --system --noninteractive --or-update flathub org.example.Second' "${flatpak_log}"
[[ "$(grep -c '^install ' "${flatpak_log}")" -eq 2 ]] \
    || { echo "FAIL: comments or blank lines were treated as applications" >&2; exit 1; }

# A partial failure must return non-zero and leave no success marker, allowing
# systemd's Restart=on-failure policy to retry the entire list later.
rm -f "${version_file}" "${flatpak_log}"
export SAGEOS_TEST_FAIL_REF=org.example.Second
setup_rc=0
"${script}" >/dev/null 2>&1 || setup_rc=$?
[[ "${setup_rc}" -ne 0 ]] || { echo "FAIL: injected install failure returned success" >&2; exit 1; }
[[ ! -e "${version_file}" ]] || { echo "FAIL: partial install wrote success marker" >&2; exit 1; }
[[ "$(grep -c '^install ' "${flatpak_log}")" -eq 2 ]] \
    || { echo "FAIL: setup stopped before attempting the complete list" >&2; exit 1; }

echo "flatpak setup PASS: idempotency, full-list install, and retry safety"
