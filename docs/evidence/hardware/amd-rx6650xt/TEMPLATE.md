# Hardware packet: AMD CPU + Radeon RX 6650 XT (Navi 23)

Reference-machine template. **Not filled.** Copy this file to a dated name
(for example `2026-09-02.md`) when recording a run, or fill these blanks in
place. Empty cells mean "not yet collected." Do not invent PCI IDs, digests,
firmware strings, or results.

Collection commands: [../README.md](../README.md).
Checklists: [../../../phase1-validation.md](../../../phase1-validation.md),
[../../../phase3-validation.md](../../../phase3-validation.md),
[../../../phase4-validation.md](../../../phase4-validation.md),
[../../../phase5-validation.md](../../../phase5-validation.md).

Intel and NVIDIA are **not** covered by this packet.

## How to fill (short)

On the booted machine:

```bash
bootc status
rpm-ostree status --booted
cat /etc/sageos-release
lspci -nn
lspci -nnk
for f in bios_vendor bios_version bios_date board_vendor board_name product_name sys_vendor; do
    printf '%s=%s\n' "$f" "$(cat /sys/class/dmi/id/$f 2>/dev/null || echo unavailable)"
done
uname -r
uname -a
ujust sageos-doctor
```

Then execute the phase checklists and paste identity + pass/fail into the
sections below. Record the immutable `sha256:…` of the **booted** image, not
the `latest` tag.

## Run identity

| Field | Value |
|---|---|
| Date (UTC) | |
| Operator | |
| Machine nickname | |
| Image reference (tag, for humans only) | `ghcr.io/sageajnz-create/sageos:` |
| **Immutable image digest** | `sha256:` |
| Signature verified? (`cosign verify` / `gh attestation verify`) | |
| Channel | testing (`latest`) / other: |
| Stock Bazzite baseline also recorded? | yes / no |

## PCI IDs

Paste `lspci -nn` / `lspci -nnk` lines. Do not type guessed vendor:device IDs.

```
(paste)
```

| Role | Slot | `lspci -nn` line (keep `[vendor:device]`) | Kernel driver (`lspci -nnk`) |
|---|---|---|---|
| GPU (expect Navi 23 / RX 6650 XT) | | | |
| HDMI/DP audio | | | |
| Chipset / onboard audio | | | |
| Ethernet | | | |
| Wi-Fi | | | |
| Bluetooth (if separate) | | | |
| Other notable | | | |

## Firmware

| Field | Value |
|---|---|
| `bios_vendor` | |
| `bios_version` | |
| `bios_date` | |
| `sys_vendor` | |
| `product_name` | |
| `board_vendor` | |
| `board_name` | |
| Secure Boot | enabled / disabled / unknown |
| GPU firmware / VBIOS (from `journalctl -k -b` amdgpu lines, or `fwupdmgr`) | |
| `fwupdmgr` notes | |

## Kernel

| Field | Value |
|---|---|
| `uname -r` | |
| `uname -a` | |

## Phase 1 machine record

| Field | Value |
|---|---|
| CPU | |
| Motherboard / chipset | |
| RAM | |
| Drives (which holds Windows / which gets SageOS) | |
| Monitors (model, resolution, refresh, VRR/HDR) | |
| Wi-Fi/BT chipset | |
| Controllers / peripherals | |

## Display / audio / controller (summary)

Fill from Phase 1 and Phase 3 metal checks. Leave blank if not run.

| Area | Result (pass / fail / skip / not run) | Notes |
|---|---|---|
| Vulkan RADV + NAVI23 (`vulkaninfo --summary`) | | |
| OpenGL radeonsi, not llvmpipe (`glxinfo -B`) | | |
| VA-API H264/HEVC/AV1 (`vainfo`) | | |
| Wayland session | | |
| VRR / adaptive sync | | |
| Native refresh rate | | |
| HDR (if the monitor supports it) | | |
| Multi-monitor / fractional scaling | | |
| PipeWire default sink (`wpctl status`) | | |
| Bluetooth audio | | |
| Controller USB | | |
| Controller Bluetooth | | |
| Suspend/resume (GPU + audio) | | |

## Rollback result

| Check | Result | Notes |
|---|---|---|
| Phase 4 #15 `sudo bootc rollback` then boot previous | | |
| Phase 5 #10 `ujust sageos-rollback` then reboot | | |
| Gaming stack intact on the previous image | | |
| Digest of the image rolled **back to** (`sha256:…`) | | |

## Limitations

Known failures, skipped checks, unverified peripherals, or "works on Bazzite
but not yet re-run on SageOS." Empty means none recorded yet — not "none
exist."

-

## Phase 1 results

Checklist: [../../../phase1-validation.md](../../../phase1-validation.md).

| # | Check | Result | Notes |
|---|---|---|---|
| 1 | Vulkan driver | | |
| 2 | GL renderer | | |
| 3 | Video decode | | |
| 4 | Wayland session | | |
| 5 | VRR | | |
| 6 | Refresh rate | | |
| 7 | Audio | | |
| 8 | Bluetooth | | |
| 9 | Controller | | |
| 10 | Steam + Proton | | |
| 11 | MangoHud | | |
| 12 | GameMode | | |
| 13 | gamescope session | | |
| 14 | ujust tooling | | |
| 15 | Network | | |
| 16 | Suspend/resume | | |
| 17 | Update path (`bootc status`) | | |

## Phase 3 results

Checklist: [../../../phase3-validation.md](../../../phase3-validation.md).
VM is acceptable for image-structure checks 1–6; graphics/input/audio need
this machine.

| # | Check | Result | Notes |
|---|---|---|---|
| 1 | Diagnostics present | | |
| 2 | Flatpak service enabled | | |
| 3 | Flatpak service ran | | |
| 4 | Our flatpaks installed | | |
| 5 | Bazzite's flatpaks intact | | |
| 6 | Re-run on list change | | |
| 7 | Vulkan | | |
| 8 | OpenGL | | |
| 9 | Video accel | | |
| 10 | VRR | | |
| 11 | HDR (desktop) | | |
| 12 | HDR (game) | | |
| 13 | Multi-monitor | | |
| 14 | Fractional scaling | | |
| 15 | Night Color | | |
| 16 | Controller (USB + BT) | | |
| 17 | Keyboard media keys | | |
| 18 | Mouse polling | | |
| 19 | PipeWire graph health | | |
| 20 | BT codec | | |
| 21 | Mic | | |
| 22 | Game + voice simultaneously | | |
| 23 | Suspend/resume audio | | |

## Phase 4 results

Checklist: [../../../phase4-validation.md](../../../phase4-validation.md).
Real hardware required for anything past #3.

| # | Check | Result | Notes |
|---|---|---|---|
| 1 | Doctor | | |
| 2 | ujust integration | | |
| 3 | Launchers installed | | |
| 4 | Steam + official Proton | | |
| 5 | Proton-GE path | | |
| 6 | EAC/BattlEye runtime | | |
| 7 | Heroic | | |
| 8 | Lutris | | |
| 9 | Bottles | | |
| 10 | Protontricks | | |
| 11 | MangoHud | | |
| 12 | GameMode | | |
| 13 | gamescope nested | | |
| 14 | Boot-to-Windows | | |
| 15 | Rollback safety | | |

## Phase 5 results

Checklist: [../../../phase5-validation.md](../../../phase5-validation.md).
Mostly VM-checkable; still record digest/kernel when this AMD box is the
system under test.

| # | Check | Result | Notes |
|---|---|---|---|
| 1 | Doctor | | |
| 2 | ujust integration | | |
| 3 | Update timer armed | | |
| 4 | No double-update path | | |
| 5 | Signature enforcement live | | |
| 6 | Tamper rejection | | |
| 7 | Pin service ran | | |
| 8 | Booted deployment pinned | | |
| 9 | Pin survives an update | | |
| 10 | Rollback recipe | | |
| 11 | Greenboot safety net | | |
