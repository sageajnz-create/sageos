# Build supply chain

Every published SageOS image runs the following controls against the final
rechunked OCI image:

1. The build job contract-tests and pushes the image by immutable digest.
2. It signs that digest with the SageOS Cosign key and publishes provenance.
3. Syft reads the RPM database from the already-local assembled Podman image
   and generates an SPDX JSON OS-package SBOM.
4. A separate job downloads that small SBOM and Grype scans it for known
   vulnerabilities with fixes available.
5. CI retains both reports for 30 days for review and baseline comparison.

The RPM-only scope is explicit: it inventories the Fedora/Bazzite/SageOS OS
packages that the project updates as an image. Full binary and language archive
cataloging of the 10+ GB gaming image exceeded GitHub-hosted runner resources;
those ecosystems require separately budgeted catalogers rather than an SBOM
claim the runner cannot reliably produce. Pull requests still generate the
package SBOM but do not run the post-publication vulnerability-report job.

## Current scanner mode: report-only (non-blocking)

Grype **must stay non-blocking**. `.github/workflows/build.yml` runs the
`supply_chain` job with `fail-build: false` and `only-fixed: true`.
`tests/test-workflow-policy.sh` fails if that `fail-build: false` line is
removed. This document does not authorize flipping that job to hard-fail.

A release-blocking threshold must be based on a reviewed baseline, ownership,
fix availability, exploitability, and documented VEX decisions—not an
arbitrary severity count. The archived Phase 6A reports are the first
baseline; they are **not** a completed triage of inherited Bazzite/Fedora
risk, and they are **not** a claim that the image is vulnerability-free.

Do not treat a pull-request SBOM as the release baseline. PR builds skip the
vulnerability job.

## Phase 6A archived Grype / SBOM baseline

Use the files and pointers under
[evidence/phase6a/](evidence/phase6a/README.md). Do not invent scanner output
or CVE lists. Quote those artifacts.

The scheduled image that the chained qcow2 booted:

| Field | Recorded value |
|---|---|
| Evidence index | [evidence/phase6a/README.md](evidence/phase6a/README.md) |
| Compact Grype copy | [evidence/phase6a/scheduled-image-vulns-summary.json](evidence/phase6a/scheduled-image-vulns-summary.json) |
| Workflow run | [33520770178](https://github.com/sageajnz-create/sageos/actions/runs/33520770178) (`schedule` on `ba734b4`) |
| Image digest | `sha256:a98c409012f60ec526788cb7ca710d5959599b4981bf466322006a03ef2e0be5` |
| Provenance | [attestation 44474222](https://github.com/sageajnz-create/sageos/attestations/44474222) |
| SBOM artifact | `sageos-sbom-33520770178` (GitHub Actions, ~20 MB SPDX JSON; **not** committed; expires 2026-10-01) |
| Vulnerability artifact | `sageos-vulnerabilities-33520770178` (GitHub Actions; expires 2026-10-01) |
| Scanner | Grype `0.110.0`, `only_fixed: true` |
| Distro recorded by Grype | Bazzite 44 |
| `match_count` | `0` |
| `matches` | `[]` |

That empty match list means Grype found **no RPM findings that already have a
fix available**. It does not mean the image has zero vulnerabilities. Unfixed
inherited CVEs are out of scope of this scanner configuration and must not be
invented here.

A second published image from the post-merge `push` is recorded in the same
evidence log (run [33515917012](https://github.com/sageajnz-create/sageos/actions/runs/33515917012),
digest `sha256:111533ed04e9b0836b7046a006d15edf177bbd64b8ecbe0bb69ce360a8a80c3a`,
artifacts `sageos-sbom-33515917012` / `sageos-vulnerabilities-33515917012`).
The chained qcow2 followed the **scheduled** digest above; use that digest as
the Phase 6A release baseline.

Refresh the compact summary from a later scheduled Grype artifact before the
30-day retention lapses (baseline artifacts expire 2026-10-01). Fetch commands
are in [evidence/phase6a/README.md](evidence/phase6a/README.md).

## Inherited Bazzite / Fedora triage policy

SageOS is a thin image on Bazzite (Fedora Atomic). Most RPMs in the SBOM are
upstream packages SageOS does not patch. Treat findings as inherited until
proven otherwise.

### Ownership

| Class | What it covers | Default disposition |
|---|---|---|
| SageOS-owned | Files and packages this repo layers: `build_files/`, `system_files/`, SageOS services/scripts, Cosign policy, and any RPM we add in `scripts.d/` | Investigate, fix or revert in this repo, or document a time-bounded exception |
| Inherited base | Bazzite/Fedora RPMs from the digest-pinned base image | Track upstream. Do not invent a SageOS patch. Rebase when Bazzite publishes a fixed digest, or record accepted risk with an expiry |
| Out of SBOM scope | Flatpaks, language archives, firmware blobs, and other ecosystems the RPM-only Syft scan does not inventory | Not part of this Grype baseline. Do not claim they were scanned |

### Classification (when `matches` is not empty)

For each real Grype match in a published `sageos-vulnerabilities-<run_id>`
artifact:

1. Record package, CVE, severity, fix version, and whether a fix is already
   available (`only-fixed: true` means every listed match has a fix somewhere).
2. Assign ownership using the table above.
3. For inherited packages: wait for Bazzite/Fedora, rebase, or accept with
   expiry. For SageOS-owned packages: patch, drop, or accept with expiry.
4. Write the decision in this file or a dated note under `docs/evidence/`
   that quotes the artifact. Do not paste invented CVE lists.

The Phase 6A compact copy has `"matches": []`, so there are **no** Grype
matches from that scan to classify today. The next non-empty scheduled report
is the first list that this procedure applies to.

### Review and expiry cadence

- **Per scheduled image:** review the Grype artifact from each successful
  scheduled `Build container image` run (the `supply_chain` job). Compare
  `match_count` and package names against
  [scheduled-image-vulns-summary.json](evidence/phase6a/scheduled-image-vulns-summary.json).
  Push-event scans are extra evidence; they are not the chained-qcow2
  baseline.
- **Calendar floor:** if no new matches appear, still record a review at
  least every 14 days that the last reviewed run ID and digest are still the
  working baseline.
- **Accepted inherited risk:** expires in 30 days or at the next Bazzite
  base-digest bump in `Containerfile`, whichever is sooner. Expired
  acceptances return to "open" and must be re-decided.
- **Accepted SageOS-owned risk:** expires in 14 days unless a later review
  extends it with a reason. Prefer a fix in this repo over renewal.
- **Artifact retention:** GitHub keeps SBOM and vuln zips 30 days. Before
  expiry, copy a compact match list into `docs/evidence/` if that report is
  still the baseline. Do not commit the 20 MB SPDX file.

Upstream security reports that reproduce on stock Bazzite belong in
[SECURITY.md](../SECURITY.md) (usually report upstream; SageOS may still
coordinate). Compromised signing keys use
[signing-and-recovery.md](signing-and-recovery.md).

## Proposed severity-gate criteria (not enabled)

These are the documented conditions for a **later** PR to set
`fail-build: true` (or an equivalent threshold). They are **not** in force.
CI stays `fail-build: false` until that later PR also updates
`tests/test-workflow-policy.sh`.

### Prerequisites before any blocking gate

1. A scheduled Grype report newer than, or equal to, the Phase 6A baseline
   has been reviewed under the policy above.
2. Ownership is assigned for every match in that report (today: zero
   matches, so this is a process check, not a CVE check).
3. An accepted-risk register exists for inherited findings the project is
   willing to ship, each with an owner and expiry date.
4. The gate still uses the same RPM-only SBOM and `only-fixed: true` unless
   a separate docs+CI change expands scope and re-baselines.

### Proposed fail conditions (once enabled)

The scan job may fail a **non-PR** image publication when **all** of these
are true for a match:

- Severity is Critical or High (Grype / CVSS as reported in the artifact).
- A fix is already available (`only-fixed: true` already filters to this).
- The package is SageOS-owned, **or** it is inherited and the fix is already
  in the current digest-pinned Bazzite base (meaning SageOS failed to rebase
  onto a base that includes the fix).
- The match is not covered by an unexpired accepted-risk entry.

New Critical/High matches versus the last reviewed compact summary should
also fail once the gate is on, unless they are immediately classified and
accepted with expiry in the same change that rebases or documents them.

### Proposed non-fail conditions (even after a gate)

- Pull requests: keep skipping the vulnerability job; do not block PR CI on
  inherited Fedora noise.
- Medium, Low, or Negligible severity.
- Inherited packages whose only fix is still **not** in the pinned Bazzite
  digest (track and rebase; do not hard-fail the SageOS image job solely
  because upstream has not shipped).
- Findings outside the RPM cataloger scope.
- Scanner or database outages: prefer `fail-build: false` or an explicit
  allow-failure path over blocking publication of a signed image the other
  jobs already validated.

### How a later PR would enable the gate

1. Confirm the prerequisites with a dated evidence note.
2. Change `fail-build: false` to the chosen threshold in
   `.github/workflows/build.yml`.
3. Update `tests/test-workflow-policy.sh` so it asserts the new policy
   instead of `fail-build: false`.
4. Point this section at that commit and retire the "not enabled" label.

Until that happens, empty `matches: []` is a baseline measurement, not a
reason to turn the scanner into a hard gate.

## Verifying an image

Resolve the tag to a digest before recording or comparing it. Verify the SageOS
signature with the committed key:

```bash
cosign verify \
  --key cosign.pub \
  ghcr.io/sageajnz-create/sageos@sha256:REPLACE_WITH_DIGEST
```

The Phase 6A scheduled digest to verify first is recorded in
[evidence/phase6a/README.md](evidence/phase6a/README.md):

```bash
cosign verify \
  --key cosign.pub \
  ghcr.io/sageajnz-create/sageos@sha256:a98c409012f60ec526788cb7ca710d5959599b4981bf466322006a03ef2e0be5
```

Verify GitHub-hosted provenance from an authenticated GitHub CLI session:

```bash
gh attestation verify \
  oci://ghcr.io/sageajnz-create/sageos@sha256:REPLACE_WITH_DIGEST \
  --repo sageajnz-create/sageos
```

Signature verification proves the digest was authorized by the SageOS signing
key. Provenance separately records where and how GitHub Actions built it.
Neither claim means the image is vulnerability-free; inspect the SBOM, scan
report, release notes, and security advisories together.

Key rotation and compromise recovery are documented in
[signing-and-recovery.md](signing-and-recovery.md).
