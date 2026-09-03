# SageOS

Gaming-first, atomic, daily-driver Linux for x86_64 PCs. Built as a custom
[bootc](https://bootc-dev.github.io/bootc/) image on top of
[Bazzite](https://bazzite.gg) (Fedora Atomic + Universal Blue).

**Status: Phase 6A exit is archived** under
[docs/evidence/phase6a/](docs/evidence/phase6a/README.md). Supply-chain
triage **policy is on main** ([docs/supply-chain.md](docs/supply-chain.md),
PR #10). **Next physical work is filling the AMD hardware evidence
packet** ([docs/evidence/hardware/](docs/evidence/hardware/README.md)).
Phase 6B / Control Center is not started. See
[docs/development-plan.md](docs/development-plan.md) for the current execution
plan and [docs/roadmap.md](docs/roadmap.md) for validated product milestones.

The next product phases, including the AI runtime, Windows compatibility,
customization system, and release gates, are defined in
[docs/development-plan.md](docs/development-plan.md). Developer-machine setup
and the local test loop are in [docs/development.md](docs/development.md).
Image-key rotation and recovery are documented in
[docs/signing-and-recovery.md](docs/signing-and-recovery.md); report security
issues using [SECURITY.md](SECURITY.md).
SBOM, vulnerability-report, signing, and provenance behavior is described in
[docs/supply-chain.md](docs/supply-chain.md).
Current x86_64 hardware boundaries and the pre-release `latest`/testing channel
contract are defined in [docs/support-policy.md](docs/support-policy.md).

## How this works

The entire OS is defined by this repo:

| Path | Purpose |
|---|---|
| `Containerfile` | Image definition — base (Bazzite KDE, digest-pinned) + our layers |
| `build_files/scripts.d/` | Numbered build stages: packages, branding, services |
| `system_files/` | Static files overlaid onto `/` in the image |
| `.github/workflows/build.yml` | CI: build → rechunk → push → cosign-sign, daily + on push |
| `.github/workflows/build-disk.yml` | On-demand installer ISO / qcow2 VM image builds |
| `disk_config/` | bootc-image-builder configs for ISO and disk images |
| `Justfile` | Local build/test recipes (`just build`, `just build-iso`, `just run-vm-qcow2`) |

Every push to `main` publishes the testing channel as
`ghcr.io/sageajnz-create/sageos:latest`. Installed
machines update to it atomically (nightly via `uupd`), verify each update
against the committed `cosign.pub` key before installing it, and can roll back
to the previous image from the GRUB menu — the running deployment is pinned at
every boot, so a known-good fallback is always on disk.

## One-time setup

1. Create a GitHub repo named `sageos`, push this tree to `main`.
2. Replace `CHANGEME` in [sageos.env](sageos.env) and `changeme` in
   [disk_config/iso.toml](disk_config/iso.toml) with your GitHub username.
3. Generate a signing key (from any Linux shell with cosign):
   `cosign generate-key-pair` — commit `cosign.pub`, add `cosign.key`'s
   contents as a repo Actions secret named `SIGNING_SECRET`.
   **Never commit `cosign.key`** (it is gitignored).
4. Run the **Build container image** workflow once (Actions tab), then make the
   published package public: GitHub → Packages → `sageos` → settings →
   Change visibility.

## Installing on a machine

Preferred path while the project is young — install stock Bazzite, then rebase:

```bash
# on a fresh Bazzite (KDE) install:
sudo bootc switch ghcr.io/sageajnz-create/sageos:latest
systemctl reboot
```

Rollback at any time: pick the previous deployment in GRUB, or
`sudo bootc rollback`. Details and the dual-boot disk plan:
[docs/install.md](docs/install.md).

SageOS has no stable channel yet. During pre-release, `latest` explicitly means
testing; see the support policy before installing on a primary machine.

## Development

```bash
just build            # build the image locally with podman
just build-qcow2      # bootable VM disk image
just run-vm-qcow2     # boot it in a browser-accessible VM
just build-iso        # installer ISO (also available from CI)
just lint             # shellcheck all build scripts
```

Local builds need Linux + podman (WSL2 works; an installed Bazzite/SageOS box
is ideal). CI does all release builds — local builds are for iteration only.
