# Build supply chain

Every SageOS image build runs the following controls against the final
rechunked OCI image, before publication:

1. Syft generates an SPDX JSON software bill of materials (SBOM).
2. Grype scans that SBOM for known vulnerabilities with fixes available.
3. CI retains both reports for 30 days for review and baseline comparison.
4. Main-branch builds push the image by immutable digest and sign that digest
   with the SageOS Cosign key.
5. GitHub Actions publishes build-provenance attestation for the same digest.

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
