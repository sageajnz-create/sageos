#!/bin/bash
# Offline test of sageos-pin: runs the exact Python embedded in the script
# (extracted from system_files/usr/libexec/sageos-pin) with a stubbed
# subprocess, then asserts the pin/unpin sequence. Cross-platform: no real
# rpm-ostree/ostree needed.
set -euo pipefail

run_py() { python3 "$@" 2>/dev/null || py -3 "$@"; }

SCRIPT="$(dirname "$0")/../system_files/usr/libexec/sageos-pin"

# --- scenario 1: three deployments, booted in the middle, others pinned ----
STATUS='{"deployments":[
 {"checksum":"aaa","booted":false,"pinned":false},
 {"checksum":"bbb","booted":true,"pinned":true},
 {"checksum":"ccc","booted":false,"pinned":true}
]}'

RESULT="$(SAGEOS_TEST_STATUS="$STATUS" SAGEOS_TEST_SCRIPT="$SCRIPT" run_py - <<'PYEOF'
import json, os, sys

src = open(os.environ["SAGEOS_TEST_SCRIPT"]).read()
code = src.split("python3 - \"${status_file}\" <<'PYEOF'\n")[1].split("\nPYEOF")[0]

calls = []
class FakeSubprocess:
    DEVNULL = -3
    @staticmethod
    def run(args, **kw):
        calls.append(list(args))
sys.modules["subprocess"] = FakeSubprocess

import tempfile
status_path = tempfile.mkstemp()[1]
open(status_path, "w", encoding="utf-8").write(os.environ.pop("SAGEOS_TEST_STATUS"))
sys.argv = ["sageos-pin", status_path]
exec(compile(code, "sageos-pin-embedded", "exec"))

expected = [
    ["ostree", "admin", "pin", "--unpin", "2"],
    ["ostree", "admin", "pin", "--unpin", "0"],
    ["ostree", "admin", "pin", "1"],
]
if calls != expected:
    print(f"FAIL: got {calls}", file=sys.stderr)
    sys.exit(1)
print("scenario 1 PASS: unpins non-booted descending, pins booted")
PYEOF
)"
echo "$RESULT"

# --- scenario 2: no booted deployment -> must do nothing -------------------
STATUS2='{"deployments":[{"checksum":"aaa","booted":false}]}'

SAGEOS_TEST_STATUS="$STATUS2" SAGEOS_TEST_SCRIPT="$SCRIPT" run_py - <<'PYEOF'
import json, os, sys

src = open(os.environ["SAGEOS_TEST_SCRIPT"]).read()
code = src.split("python3 - \"${status_file}\" <<'PYEOF'\n")[1].split("\nPYEOF")[0]

calls = []
class FakeSubprocess:
    DEVNULL = -3
    @staticmethod
    def run(args, **kw):
        calls.append(list(args))
sys.modules["subprocess"] = FakeSubprocess

import tempfile
status_path = tempfile.mkstemp()[1]
open(status_path, "w", encoding="utf-8").write(os.environ.pop("SAGEOS_TEST_STATUS"))
sys.argv = ["sageos-pin", status_path]
try:
    exec(compile(code, "sageos-pin-embedded", "exec"))
except SystemExit:
    pass  # the embedded script exits early when no deployment is booted

if calls:
    print(f"FAIL: expected no calls, got {calls}", file=sys.stderr)
    sys.exit(1)
print("scenario 2 PASS: no booted deployment means no calls")
PYEOF
