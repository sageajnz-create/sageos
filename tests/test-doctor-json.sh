#!/usr/bin/env bash
# Verify that the doctor always emits a stable, parseable machine report.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
doctor="${repo_root}/system_files/usr/libexec/sageos-doctor"

doctor_rc=0
report="$(bash "${doctor}" --json)" || doctor_rc=$?
[[ "${doctor_rc}" -eq 0 || "${doctor_rc}" -eq 1 ]] || {
    echo "FAIL: doctor returned unexpected status ${doctor_rc}" >&2
    exit 1
}

python3 -c '
import json
import sys

report = json.load(sys.stdin)
assert report["schema_version"] == 1
assert isinstance(report["healthy"], bool)
summary = report["summary"]
checks = report["checks"]
assert set(summary) == {"passed", "warnings", "failed"}
assert sum(summary.values()) == len(checks)
assert all(set(check) == {"status", "section", "message"} for check in checks)
assert all(check["status"] in {"pass", "warn", "fail"} for check in checks)
assert report["healthy"] == (summary["failed"] == 0)
' <<<"${report}"

echo "doctor JSON PASS: schema, counts, and health status are consistent"
