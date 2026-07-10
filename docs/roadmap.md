# SageOS Roadmap

| Phase | Scope | Status |
|---|---|---|
| 1 | Architecture decision, base distro choice (Bazzite/uBlue bootc image) | ✅ approved 2026-07-10 |
| 2 | Image pipeline, repo scaffold, installer strategy, base system layout | ✅ 2026-07-10 (pending CI-green confirmation) |
| 3 | Desktop, input, audio, graphics stack (Plasma/Wayland defaults, VRR/HDR validation, default Flatpaks) | 🔨 built, awaiting hardware validation |
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

## Phase 3 decisions (2026-07-10)

- Desktop-first boot flow confirmed. Verified against the Bazzite repo: the
  desktop variant ships gamescope only as a nested compositor (per-game
  wrapping works; no boot-to-Game-Mode session). Console-first boot = swap the
  Containerfile base to `bazzite-deck` — a one-line change, revisit in Phase 6.
- Default flatpaks: Bazzite's first-boot set is kept untouched; SageOS
  additions live in `/usr/share/sageos/flatpaks.list`, applied by our own
  `sageos-flatpak-setup.service` (hash-versioned, re-runs when the list
  changes in an image update, retries until network is up).
- Plasma theming/branding deferred to Phase 6; no KDE config defaults shipped
  yet — stock Bazzite KDE defaults are good, and every default we ship is a
  default we maintain.
- Diagnostics (`vulkaninfo`, `glxinfo`, `vainfo`) are layered into the image
  so validation checklists run on any install without setup.
