# Phase 3 validation — desktop, input, audio, graphics

Run on a SageOS image (VM for structure checks, **real hardware for anything
involving the GPU, displays, or audio**). Extends, not replaces,
[phase1-validation.md](phase1-validation.md).

## Image structure (VM is fine)

| # | Check | Command | Pass criteria |
|---|---|---|---|
| 1 | Diagnostics present | `command -v vulkaninfo glxinfo vainfo` | all found |
| 2 | Flatpak service enabled | `systemctl is-enabled sageos-flatpak-setup` | `enabled` |
| 3 | Flatpak service ran | `systemctl status sageos-flatpak-setup`; `cat /etc/sageos/flatpak_setup_version` | exited 0, version hash recorded |
| 4 | Our flatpaks installed | `flatpak list --system \| grep -i libreoffice` | present |
| 5 | Bazzite's flatpaks intact | `flatpak list --system` | Firefox, Haruna, ProtonUp-Qt, MangoHud layer present |
| 6 | Re-run on list change | edit list hash scenario: `rm /etc/sageos/flatpak_setup_version && systemctl start sageos-flatpak-setup` | re-applies cleanly, idempotent |

## Graphics (RX 6650 XT, real hardware)

| # | Check | Command / method | Pass criteria |
|---|---|---|---|
| 7 | Vulkan | `vulkaninfo --summary` | `radv` + NAVI23, no llvmpipe fallback |
| 8 | OpenGL | `glxinfo -B` | radeonsi |
| 9 | Video accel | `vainfo` | H264/HEVC/AV1 decode profiles |
| 10 | VRR | Plasma Display Settings → Adaptive Sync "Automatic"; run a game, watch monitor OSD Hz | Hz tracks framerate |
| 11 | HDR (desktop) | Display Settings → HDR toggle (if monitor supports) | enables, colors sane |
| 12 | HDR (game) | gamescope-wrapped game with HDR | engages, no washout |
| 13 | Multi-monitor | mixed refresh/scale if available | per-display settings hold across reboot |
| 14 | Fractional scaling | 125%/150% on one display | crisp XWayland + Wayland apps |
| 15 | Night Color | enable in settings | activates without flicker |

## Input

| # | Check | Method | Pass criteria |
|---|---|---|---|
| 16 | Controller (USB + BT) | pair, test in Steam → controller settings | detected, mappable, rumble works |
| 17 | Keyboard media keys | volume/brightness/play | act correctly |
| 18 | Mouse polling | high-poll gaming mouse if present | no stutter at 1000Hz+ |

## Audio (PipeWire)

| # | Check | Method | Pass criteria |
|---|---|---|---|
| 19 | Graph health | `wpctl status` | correct default sink/source, no missing nodes |
| 20 | BT codec | pair BT headphones, `wpctl inspect` the sink | AAC/aptX/LDAC negotiated (not SBC-only if hw supports better) |
| 21 | Mic | record in any app | clean capture, correct device |
| 22 | Game + voice simultaneously | game audio + Discord/Signal call | no dropouts, independent volumes in `wpctl`/plasma-pa |
| 23 | Suspend/resume audio | suspend → wake → play | sinks return without restart |

## Run log

| Date | Image tag | Section | Result | Notes |
|---|---|---|---|---|
| | | | | |
