# Image signing and recovery

SageOS CI signs the pushed image digest with Cosign. Installed systems require
that signature for the `ghcr.io/sageajnz-create/sageos` repository through
`/etc/containers/policy.json`. The matching public key is embedded at
`/etc/pki/containers/cosign.pub`; the private key exists only in the GitHub
Actions secret `SIGNING_SECRET`.

The two committed public-key copies (`cosign.pub` and the image overlay copy)
must remain byte-identical. `just validate` enforces this.

Cosign publishes signatures as OCI tag attachments (`sha256-<digest>.sig`). The
image also ships `/etc/containers/registries.d/ghcr.io-sageajnz-create-sageos.yaml`
so containers/image looks up those attachments for `ghcr.io/sageajnz-create/sageos`
only. Existing installs that predate that lookaside (or whose ostree `/etc` merge
kept a stock `policy.json`) should use `scripts/repair-signature-policy.sh` on
`main`, which installs the same trio: `cosign.pub`, SageOS-scoped
`sigstoreSigned` `policy.json`, and the registries.d lookaside.

## Normal key rotation

Because the current containers policy accepts one key, rotation requires a
bridge image. Do not replace the secret first: machines trusting the old key
would reject the first image signed only by the new key.

1. Generate the new key pair on a trusted offline workstation. Store the new
   private key in the project's credential backup and record its fingerprint.
2. Change the single `sigstoreSigned` requirement from `keyPath` to `keyPaths`,
   listing the old and new public keys at distinct embedded paths. Do not add
   two requirement objects: policy requirement arrays are cumulative, which
   would incorrectly require signatures from both keys.
3. Build and sign the bridge image with the old key. Verify it by digest, then
   allow installed systems to receive it.
4. Replace `SIGNING_SECRET` with the new private key. Build and sign a second
   image with the new key and verify that a bridge deployment accepts it.
5. After the announced migration window, remove the old key and old-key rule in
   a new-key-signed image. Retain the old public key and audit record; securely
   retire the old private key according to the backup policy.

Test every stage on a disposable qcow2 before publishing it. Never use a tag as
the verification record; record the immutable image digest and commit.

## Lost private key

If the private key is lost but is not suspected compromised, existing machines
remain safe but cannot accept newly signed SageOS images. Recover the key from
the protected backup. If no backup exists, publish a recovery procedure through
trusted project channels. Users must explicitly install a new trust root or
rebase from newly verified installation media; this cannot be repaired through
the old automatic update channel.

## Suspected compromise

1. Disable image publication and automatic scheduled builds.
2. Remove or restrict the compromised GitHub Actions secret and revoke access
   that may have exposed it.
3. Preserve workflow, registry, and access logs. Identify the last trusted
   commit and image digest without pulling an untrusted `latest` tag.
4. Publish a GitHub Security Advisory listing trusted and suspect digests.
5. Generate a replacement key offline and prepare clean recovery media. Do not
   sign a bridge image with a key that may be attacker-controlled.
6. Require affected users to boot a pinned known-good deployment or verified
   recovery media, install the new trust root explicitly, and only then resume
   updates.

SageOS deployment pinning provides a local known-good rollback candidate, but
it is not proof that a deployment predates compromise. Compare its image digest
against the advisory before treating it as trusted.

## Recovery-key backup checklist

- Keep at least two encrypted private-key backups in separate locations.
- Store recovery credentials separately from the GitHub account and runner.
- Record who can access each backup and test restoration at least annually.
- Never commit `cosign.key`, paste it into issues or logs, or store it in the OS
  image. The repository `.gitignore` is only a guardrail, not secret storage.
- Rotate immediately after any unexplained disclosure or access-control event.
