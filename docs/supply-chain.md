# Build supply chain

Every published SageOS image runs the following controls against the final
rechunked OCI image:

1. The build job contract-tests and pushes the image by immutable digest.
2. It signs that digest with the SageOS Cosign key and publishes provenance.
3. A separate job asks Syft to generate an SPDX JSON SBOM directly from that
   authenticated registry digest, rather than exporting a second local archive.
4. Grype scans that SBOM for known vulnerabilities with fixes available.
5. CI retains both reports for 30 days for review and baseline comparison.

Separating analysis from the build gives the scanners an independent runner
lifetime and prevents a scanner interruption from discarding an already
validated image. Pull requests build and contract-test without publishing, so
their unpublished local image does not enter the registry-based scan job.

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
