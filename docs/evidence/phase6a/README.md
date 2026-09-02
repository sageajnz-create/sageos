# Phase 6A evidence log

This folder is the beginner-friendly archive for the engineering-foundation
gate in `docs/development-plan.md`. It records **real GitHub Actions run IDs,
artifact names, and doctor JSON**. Nothing here is invented.

Phase 6A **engineering-foundation evidence is archived** (2026-09-01). Phase
6B / Control Center is **not started**.

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
| Post-merge `latest` image (`push`) | Green | [run 33515917012](https://github.com/sageajnz-create/sageos/actions/runs/33515917012) digest `sha256:111533ed04e9b0836b7046a006d15edf177bbd64b8ecbe0bb69ce360a8a80c3a` |
| Push-triggered disk chain | Skipped (by design) | [run 33527589159](https://github.com/sageajnz-create/sageos/actions/runs/33527589159) |
| Scheduled `latest` image on `ba734b4` | Green | [run 33520770178](https://github.com/sageajnz-create/sageos/actions/runs/33520770178) digest `sha256:a98c409012f60ec526788cb7ca710d5959599b4981bf466322006a03ef2e0be5` |
| Scheduled/chained qcow2 of that `latest` | **Green** | [run 33535434052](https://github.com/sageajnz-create/sageos/actions/runs/33535434052) (`workflow_run` after the scheduled image) |
| SBOM + vuln report + provenance for the scheduled digest | Archived as pointers + compact Grype copy | See tables below; doctor snapshot [`chained-qcow2-doctor.json`](chained-qcow2-doctor.json) |

Phase 6B / Control Center remains **not started**. Next work is supply-chain
triage ([docs/supply-chain.md](../../supply-chain.md): inherited
Bazzite/Fedora policy, review/expiry cadence, proposed non-blocking
severity-gate criteria) and then hardware checklists, not a GUI.

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
`ba734b4` and is inside both post-merge `latest` digests below. The chained
qcow2 below is the proof for that published image.

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

## Published images after the PR #8 merge (real digests)

Do not record the `latest` tag as the evidence. These came from the workflow
“Push To GHCR” / attest logs.

| Event | Run | Digest | Provenance | SBOM artifact | Vuln artifact |
|---|---|---|---|---|---|
| `push` after merge | [33515917012](https://github.com/sageajnz-create/sageos/actions/runs/33515917012) | `sha256:111533ed04e9b0836b7046a006d15edf177bbd64b8ecbe0bb69ce360a8a80c3a` | [attestation 44455244](https://github.com/sageajnz-create/sageos/attestations/44455244) | `sageos-sbom-33515917012` (expires 2026-10-01) | `sageos-vulnerabilities-33515917012` |
| `schedule` on `ba734b4` | [33520770178](https://github.com/sageajnz-create/sageos/actions/runs/33520770178) | `sha256:a98c409012f60ec526788cb7ca710d5959599b4981bf466322006a03ef2e0be5` | [attestation 44474222](https://github.com/sageajnz-create/sageos/attestations/44474222) | `sageos-sbom-33520770178` (expires 2026-10-01) | `sageos-vulnerabilities-33520770178` |

The chained qcow2 started after the scheduled image, so it pulled `latest` as
it existed at 17:01 UTC: digest `sha256:a98c4090…`.

Compact copy of the scheduled Grype match list:
[`scheduled-image-vulns-summary.json`](scheduled-image-vulns-summary.json).
`match_count` is `0` with `only_fixed: true` (Grype 0.110.0, Bazzite 44).
That means **no RPM findings that already have a fix**, not “the image has
zero vulnerabilities”. The 20 MB SPDX SBOM stays in GitHub Actions; do not
commit it.

## Chained qcow2 doctor (the Phase 6A exit artifact)

Copied from GitHub artifact `vm-validation-33535434052` on disk run
[33535434052](https://github.com/sageajnz-create/sageos/actions/runs/33535434052)
(finished 2026-09-01T17:34:15Z, “Boot and validate qcow2” step green):

| Field | Value |
|---|---|
| Snapshot | [`chained-qcow2-doctor.json`](chained-qcow2-doctor.json) |
| `"healthy"` | `true` |
| Summary | `passed: 15`, `warnings: 10`, `failed: 0` |
| Journal excerpt | [`chained-qcow2-pin-journal-excerpt.txt`](chained-qcow2-pin-journal-excerpt.txt) |
| Full journal / serial log | artifact `vm-validation-33535434052` (expires 2026-09-15) |
| QCOW2 disk image | artifact `qcow2-33535434052` (very large; do not commit) |

The ten warnings are the expected headless-VM class: llvmpipe, no Wayland
session, no default audio device, and first-boot Flatpaks still installing.
Signature enforcement passed. Deployment pin **passed**:
`booted deployment pinned — rollback point guaranteed`.

The image’s own `sageos-pin.service` succeeded in the guest journal (`res=success`).
That is the E2BIG failure from the older `latest` gone. The validator still
copies this checkout’s doctor/policy into the guest (same as PR CI); the pin
service result above is from the **published image**, not from that copy.

Phase 6A exit is met: PR image validation green, and one green
scheduled-image → chained qcow2 boot with a healthy machine-readable doctor
report, plus SBOM / vuln / provenance pointers for that digest.

## How to fetch artifacts (copy-paste)

You need the GitHub CLI (`gh`) and must be logged in (`gh auth status`).

```bash
# 1. See the newest runs on main
gh run list --repo sageajnz-create/sageos --branch main --limit 20

# 2. Download PR #8 qcow2 doctor/journal (already snapshotted above)
mkdir -p /tmp/sageos-evidence
gh run download 33491763845 --repo sageajnz-create/sageos --dir /tmp/sageos-evidence/pr8-disk

# 3. Post-merge push image (already finished)
gh run download 33515917012 --repo sageajnz-create/sageos --dir /tmp/sageos-evidence/post-merge-image

# 4. Scheduled image that the chained qcow2 follows (already finished)
gh run download 33520770178 --repo sageajnz-create/sageos --dir /tmp/sageos-evidence/scheduled-image

# 5. Chained qcow2 (already finished; doctor snapshotted above)
gh run download 33535434052 --repo sageajnz-create/sageos --name vm-validation-33535434052 --dir /tmp/sageos-evidence/chained-qcow2
python3 -m json.tool /tmp/sageos-evidence/chained-qcow2/doctor.json
```

Optional faster path after `latest` is published, if you do not want to wait
for 10:05 UTC: GitHub → Actions → **Build disk images** → Run workflow
(`workflow_dispatch`). That boots current `latest` and uploads
`vm-validation-<run_id>`. It is useful evidence, but the written Phase 6A
exit is still the **scheduled/chained** run.

Do not commit `cosign.key` or any GitHub secret. Artifact zips can include
firmware blobs (`OVMF_VARS.fd`); keep those out of git. Only the small
`doctor.json` snapshot belongs in this folder.

## Verify the scheduled digest (the one the chained qcow2 should boot)

```bash
cosign verify \
  --key cosign.pub \
  ghcr.io/sageajnz-create/sageos@sha256:a98c409012f60ec526788cb7ca710d5959599b4981bf466322006a03ef2e0be5

gh attestation verify \
  oci://ghcr.io/sageajnz-create/sageos@sha256:a98c409012f60ec526788cb7ca710d5959599b4981bf466322006a03ef2e0be5 \
  --repo sageajnz-create/sageos
```
