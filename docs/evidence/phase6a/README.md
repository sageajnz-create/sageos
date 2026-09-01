# Phase 6A evidence log

This folder is the beginner-friendly archive for the engineering-foundation
gate in `docs/development-plan.md`. It records **real GitHub Actions run IDs,
artifact names, and doctor JSON**. Nothing here is invented.

Phase 6A is **not closed** until the remaining row in the scoreboard below is
green.

## What the gate actually asks for

Two independent proofs:

1. **Pull-request image validation is green.** Offline tests plus an assembled
   OCI image structure check on the PR. This does **not** publish `latest`.
2. **One green scheduled/chained qcow2 boot** of the published `latest` image,
   with a machine-readable `doctor.json` that reports `"healthy": true`, plus
   the journal, SBOM, vulnerability report, and provenance for that image.

Pull-request disk CI boots whatever `ghcr.io/sageajnz-create/sageos:latest`
already is. It also copies this checkout's `sageos-doctor` and containers
policy into the guest (`scripts/validate-qcow2.exp`). Treat PR qcow2 as proof
that the **disk pipeline and validator** work, not as proof that the
**newly merged image** is the one that booted.

The nightly disk workflow follows the **scheduled** container build only. A
push to `main` publishes `latest` but does **not** start the chained VM gate.
That restriction is intentional (see `tests/test-workflow-policy.sh`).

## Scoreboard (2026-09-01)

| Proof | Status | Where |
|---|---|---|
| PR #8 image validation | Green | [run 33491763846](https://github.com/sageajnz-create/sageos/actions/runs/33491763846) on `69a6a2f` |
| PR #8 ISO + qcow2 boot/doctor | Green | [run 33491763845](https://github.com/sageajnz-create/sageos/actions/runs/33491763845) on `69a6a2f` |
| PR #8 merged to `main` | Done | merge commit `ba734b4` |
| Post-merge `latest` image on `main` | In progress when this note was written | [run 33515917012](https://github.com/sageajnz-create/sageos/actions/runs/33515917012) (`push`, not `schedule`) |
| Scheduled/chained qcow2 of that `latest` | **Not started** | Disk CI only chains after a **successful scheduled** image build on `main` |
| SBOM + vuln report + provenance for the post-merge digest | Waiting on 33515917012 (and its scan job) | See “How to fetch artifacts” |

Do not start Control Center / Phase 6B until the scheduled/chained qcow2 row
is green and its `doctor.json` is copied next to this README.

## PR #8 qcow2 doctor (real output)

Copied from artifact `vm-validation-33491763845` on disk run 33491763845:

- File: [`pr8-qcow2-doctor.json`](pr8-qcow2-doctor.json)
- `"healthy": true`
- `passed: 14`, `warnings: 11`, `failed: 0`

The eleven warnings are the expected headless-VM class: llvmpipe, no Wayland
session, no default audio device, first-boot Flatpaks still installing, and
the booted deployment not yet pinned.

### Honest caveat about that doctor run

The guest journal shows the **image's** `sageos-pin.service` failed:

```
sageos-pin[892]: /usr/libexec/sageos-pin: line 24: /usr/bin/python3: Argument list too long
Failed to start sageos-pin.service
```

Full excerpt: [`pr8-qcow2-pin-journal-excerpt.txt`](pr8-qcow2-pin-journal-excerpt.txt).
The published image that booted was still the pre-PR-8 `latest` (see digest
below). PR #8 already changed `sageos-pin` and `sageos-doctor` to pass
rpm-ostree JSON through a file instead of the environment. That fix is in
`ba734b4` and will only be inside `latest` after post-merge image run
33515917012 (or a later scheduled rebuild) finishes.

The validator then installed this checkout's doctor and policy into the guest
and ran `/tmp/sageos-doctor-ci --json`. So the healthy JSON above is the **PR
#8 doctor against the older published image**, not the in-image doctor from
`ba734b4`.

## Image that the PR #8 qcow2 actually booted

Disk CI pulled `ghcr.io/sageajnz-create/sageos:latest`. At that moment,
`latest` came from the last successful scheduled image build:

| Field | Value |
|---|---|
| Image workflow | [run 33419791766](https://github.com/sageajnz-create/sageos/actions/runs/33419791766) (`schedule`, success) |
| Digest from the push step | `sha256:2e78deaa75e05d75b00c9bcac4b0e5bb419d38ab217b0c9af9c3e06e2854e55d` |
| Provenance attestation | https://github.com/sageajnz-create/sageos/attestations/44233147 |
| SBOM artifact | `sageos-sbom-33419791766` (30-day retention) |
| Vulnerability artifact | `sageos-vulnerabilities-33419791766` (30-day retention) |
| Following chained qcow2 | [run 33430414211](https://github.com/sageajnz-create/sageos/actions/runs/33430414211) **failed** while building the disk (empty builder policy). That is the bug PR #8 fixed. |

The PR #8 disk job later proved the fixed builder path: qcow2 boot + ISO both
green. That is pipeline evidence, not a replacement for a chained run of the
**new** `latest`.

PR image run 33491763846 uploaded `sageos-sbom-33491763846` but skipped the
vulnerability job (that job only runs on non-PR events).

## What is still missing for Phase 6A exit

1. Confirm [run 33515917012](https://github.com/sageajnz-create/sageos/actions/runs/33515917012) is **success**, including “Scan SBOM for vulnerabilities”.
2. Record the new digest from that run’s “Push To GHCR” step (search the log
   for `digest=sha256:`). Do not treat the `latest` tag as the record.
3. Wait for the next **scheduled** container build on `main` (`cron` is
   `05 10 * * *`, 10:05 UTC). If that build is green, GitHub starts “Build
   disk images” automatically and runs **qcow2 only**.
4. Download that chained run’s `vm-validation-<run_id>` artifact. Confirm
   `doctor.json` has `"healthy": true` and `"failed": 0`. Copy it into this
   folder as `chained-qcow2-doctor.json`. Do not type the JSON by hand.
5. Keep pointers to that run’s journal, the image run’s SBOM, vulnerability
   JSON, and provenance attestation.

Until step 4 is done, say “Phase 6A evidence is incomplete”, not “Phase 6A
is done”.

## How to fetch artifacts (copy-paste)

You need the GitHub CLI (`gh`) and must be logged in (`gh auth status`).

```bash
# 1. See the newest runs on main
gh run list --repo sageajnz-create/sageos --branch main --limit 20

# 2. Download PR #8 qcow2 doctor/journal (already snapshotted above)
mkdir -p /tmp/sageos-evidence
gh run download 33491763845 --repo sageajnz-create/sageos --dir /tmp/sageos-evidence/pr8-disk

# 3. After post-merge image 33515917012 finishes:
gh run view 33515917012 --repo sageajnz-create/sageos
gh run download 33515917012 --repo sageajnz-create/sageos --dir /tmp/sageos-evidence/post-merge-image
# Look for sageos-sbom-33515917012 and sageos-vulnerabilities-33515917012

# 4. After a successful scheduled image run, find the chained disk run
#    (event will be workflow_run, name "Build disk images") and download:
# gh run download <DISK_RUN_ID> --repo sageajnz-create/sageos --dir /tmp/sageos-evidence/chained-qcow2
# python3 -m json.tool /tmp/sageos-evidence/chained-qcow2/vm-validation-*/doctor.json
```

Optional faster path after `latest` is published, if you do not want to wait
for 10:05 UTC: GitHub → Actions → **Build disk images** → Run workflow
(`workflow_dispatch`). That boots current `latest` and uploads
`vm-validation-<run_id>`. It is useful evidence, but the written Phase 6A
exit is still the **scheduled/chained** run.

Do not commit `cosign.key` or any GitHub secret. Artifact zips can include
firmware blobs (`OVMF_VARS.fd`); keep those out of git. Only the small
`doctor.json` snapshot belongs in this folder.

## Verify the digest (after post-merge publish)

Replace the digest with the one from the image log:

```bash
cosign verify \
  --key cosign.pub \
  ghcr.io/sageajnz-create/sageos@sha256:REPLACE_WITH_DIGEST

gh attestation verify \
  oci://ghcr.io/sageajnz-create/sageos@sha256:REPLACE_WITH_DIGEST \
  --repo sageajnz-create/sageos
```
