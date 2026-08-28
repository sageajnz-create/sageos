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

The scanner initially runs in report-only mode. SageOS inherits a large package
set from Bazzite and Fedora, so a release-blocking threshold must be based on a
reviewed baseline, ownership, fix availability, exploitability, and documented
VEX decisions—not an arbitrary severity count. Moving to a blocking gate is a
Phase 6A exit task after the first reports have been triaged.

## Verifying an image

Resolve the tag to a digest before recording or comparing it. Verify the SageOS
signature with the committed key:

```bash
cosign verify \
  --key cosign.pub \
  ghcr.io/sageajnz-create/sageos@sha256:REPLACE_WITH_DIGEST
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
