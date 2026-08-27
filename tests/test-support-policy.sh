#!/usr/bin/env bash
# Keep architecture and release-channel claims aligned with CI and docs.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
policy="${repo_root}/docs/support-policy.md"
disk_workflow="${repo_root}/.github/workflows/build-disk.yml"

fail() {
    echo "FAIL: $*" >&2
    exit 1
}

grep -Fq '**Architecture:** x86_64 only.' "${policy}" || fail "x86_64 support boundary missing"
# Backticks are literal Markdown in the policy text.
# shellcheck disable=SC2016
grep -Fq '`latest` is retained as the testing tag' "${policy}" || fail "latest channel semantics missing"
grep -Fq 'not published during the pre-release phase' "${policy}" || fail "stable pre-release status missing"
grep -Fq 'runs-on: ubuntu-24.04' "${disk_workflow}" || fail "disk CI is not pinned to x86_64 runner policy"
if grep -Eq 'ubuntu-[^[:space:]]*-arm|platform:[[:space:]]*arm64' "${disk_workflow}"; then
    fail "disk CI advertises unsupported ARM artifacts"
fi

echo "support policy PASS: testing/stable semantics and x86_64 CI agree"
