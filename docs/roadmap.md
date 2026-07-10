# SageOS Roadmap

| Phase | Scope | Status |
|---|---|---|
| 1 | Architecture decision, base distro choice (Bazzite/uBlue bootc image) | ✅ approved 2026-07-10 |
| 2 | Image pipeline, repo scaffold, installer strategy, base system layout | ✅ 2026-07-10 (pending CI-green confirmation) |
| 3 | Desktop, input, audio, graphics stack (Plasma/Wayland defaults, VRR/HDR validation, default Flatpaks) | 🔨 built, awaiting hardware validation |
| 4 | Gaming stack & compatibility layers (Proton-GE, Lutris/Heroic/Bottles, shader cache, per-title notes) | 🔨 built, awaiting hardware validation |
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

## Phase 4 decisions (2026-07-10)

- Proton strategy: **no layered Proton**. Official Proton via Steam; GE builds
  user-managed via ProtonUp-Qt (in base). Layering Proton would couple game
  compatibility to OS image releases — exactly the wrong cadence.
- Launchers ship as flatpaks via our list: Heroic, Lutris, Bottles,
  Protontricks. Steam/GameMode/gamescope/MangoHud confirmed native in the
  Bazzite base (verified in their Containerfile, not assumed).
- Virtualization fallback + boot-to-Windows: **already in base** as
  `ujust setup-virtualization` and `ujust setup-boot-windows-steam` — user-run
  commands, not image defaults; documented in gaming.md. Phase 5's planned
  virt RPM layering is cancelled as redundant.
- SageOS ujust recipes registered via `70-sageos.just` (import appended to the
  master justfile — Bazzite's own mechanism). First recipes: `sageos-doctor`
  (automated health check), `sageos-version`.
- Anti-cheat/per-title truth lives in docs/gaming.md, pointing at
  areweanticheatyet.com + protondb.com rather than maintaining a static list.

## Validation run: 2026-07-10 (QEMU/KVM VM, image from CI build #1)

First boot of SageOS as a running OS. `sageos-doctor`: **10 PASS / 8 WARN /
1 FAIL** — all WARNs were the expected headless-VM class (llvmpipe, no
Wayland/audio session, flatpak install still in flight).

Confirmed working: SageOS branding on login banner; booted deployment
identified as SageOS image; Steam/gamescope/MangoHud native;
sageos-flatpak-setup service enabled AND observed mid-install over the VM's
NAT (LibreOffice + Heroic already installed); ujust wiring
(`ujust sageos-version`); podman.socket; layered diagnostics present.

Issues found and fixed:
1. `gamemoded` missing from the bazzite:stable digest → layered `gamemode`
   (scripts.d/10-packages.sh).
2. anaconda-iso bib depsolve failure root-caused: image ships terra-mesa
   `enabled=1` (base build intends disabled; a terra-release-mesa update
   rewrites it) + file:// gpgkey that bib resolves against the *builder*
   filesystem → scripts.d/15-repo-fixes.sh restores enabled=0.
3. Template fixes upstreamable: build-disk.yml needed GHCR login (private
   packages) and explicit `--rootfs btrfs` for Bazzite-based images.
4. bib `[customizations.services]` (sshd) was NOT honored for the qcow2;
   user + password + ssh key customizations WERE. VM access path is serial
   console login (test/sageos) — documented in disk_config/disk.toml.

Still requires real hardware: RADV/VRR/HDR, audio devices, controllers,
EAC title, boot-to-Windows, rollback-under-use (phase 1/3/4 checklists).

Post-fix verification (same day): image rebuild green; build-disk run
29066771454 — **both** qcow2 and anaconda-iso legs green. The SageOS
installer ISO builds successfully as of this run (still a Phase 7
deliverable; the recommended install path remains Bazzite ISO → rebase).
