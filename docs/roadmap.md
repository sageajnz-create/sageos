# SageOS Roadmap

| Phase | Scope | Status |
|---|---|---|
| 1 | Architecture decision, base distro choice (Bazzite/uBlue bootc image) | ✅ approved 2026-07-10 |
| 2 | Image pipeline, repo scaffold, installer strategy, base system layout | 🔨 in progress |
| 3 | Desktop, input, audio, graphics stack (Plasma/Wayland defaults, VRR/HDR validation, default Flatpaks) | ⬜ |
| 4 | Gaming stack & compatibility layers (Proton-GE, Lutris/Heroic/Bottles, shader cache, per-title notes) | ⬜ |
| 5 | System services, rollback & update policy (uupd, pinning, signed-image enforcement, virt fallback) | ⬜ |
| 6 | Performance tuning & polish (branding, boot splash, defaults, latency/scheduler tuning) | ⬜ |
| 7 | Packaging, release & maintenance (ISO releases, versioned tags, update cadence, docs) | ⬜ |

Rule of engagement: each phase ends with a validation checklist run on real
hardware and explicit sign-off before the next begins.

## Architecture decisions (ratified end of Phase 1)

- Base: Bazzite KDE `:stable` (digest-pinned), custom OCI image via uBlue image-template model
- Updates: image-based (bootc/rpm-ostree) from ghcr.io; rollback via ostree deployments
- Desktop: KDE Plasma 6 / Wayland; gamescope-session available for console mode
- FS: Btrfs; audio: PipeWire; GPU: Mesa RADV (AMD-first)
- Apps: Flatpak-first; CLI via brew; dev via distrobox; layered RPMs last resort
- Kernel anti-cheat titles: dual-boot Windows (VMs are not a fallback for AC)
- macOS: experimental only (VM-based), never advertised as a feature
