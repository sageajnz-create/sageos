#!/usr/bin/env bash
# Offline checks for scripts/retry.sh backoff and exit-code preservation.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
retry="${repo_root}/scripts/retry.sh"

fail() {
    echo "FAIL: $*" >&2
    exit 1
}

[[ -x "${retry}" ]] || fail "scripts/retry.sh is not executable"

tmp="$(mktemp -d)"
trap 'rm -rf "${tmp}"' EXIT

# Succeeds on the first try.
if ! "${retry}" --attempts 3 --delay-seconds 0 -- true; then
    fail "retry.sh failed a command that succeeds immediately"
fi

# Recovers after transient failures, matching podman 125 / registry 5xx.
count_file="${tmp}/count"
flaky="${tmp}/flaky.sh"
echo 0 >"${count_file}"
cat >"${flaky}" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
count_file="$1"
n=$(<"${count_file}")
n=$((n + 1))
printf '%s\n' "${n}" >"${count_file}"
if ((n < 3)); then
    exit 125
fi
EOF
chmod +x "${flaky}"
if ! "${retry}" --attempts 5 --delay-seconds 0 -- "${flaky}" "${count_file}"; then
    fail "retry.sh did not recover after transient exit 125"
fi
[[ "$(<"${count_file}")" == "3" ]] || fail "retry.sh did not run until success"

# Exhausts attempts and preserves the command's exit code.
fail125="${tmp}/fail125.sh"
cat >"${fail125}" <<'EOF'
#!/usr/bin/env bash
exit 125
EOF
chmod +x "${fail125}"
rc=0
"${retry}" --attempts 3 --delay-seconds 0 -- "${fail125}" || rc=$?
[[ "${rc}" -eq 125 ]] || fail "retry.sh did not preserve exit 125 (got ${rc})"

# Missing command is a usage error, not a retried failure.
rc=0
"${retry}" --attempts 2 --delay-seconds 0 || rc=$?
[[ "${rc}" -eq 2 ]] || fail "retry.sh usage error should exit 2 (got ${rc})"

echo "retry PASS: recovers from exit 125, preserves persistent failures, and validates usage"
