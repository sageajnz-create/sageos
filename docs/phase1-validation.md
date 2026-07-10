# Phase 1 hardware validation checklist

Run on stock Bazzite (live USB or test install) on the target machine, and
re-run against every SageOS image before promoting it. Record results per run.

Machine: AMD CPU + Radeon RX 6650 XT (Navi 23) — fill in exact specs below.

| # | Check | Command / method | Pass criteria |
|---|---|---|---|
| 1 | Vulkan driver | `vulkaninfo --summary` | `driverName = radv`, device shows NAVI23 |
| 2 | GL renderer | `glxinfo -B` (or `eglinfo`) | radeonsi, not llvmpipe |
| 3 | Video decode | `vainfo` | VA-API profiles listed (H264/HEVC/AV1 decode) |
| 4 | Wayland session | `echo $XDG_SESSION_TYPE` | `wayland` |
| 5 | VRR | Plasma Display Settings | Adaptive sync toggle present + monitor engages |
| 6 | Refresh rate | Display settings | Native max refresh selectable |
| 7 | Audio | Play audio, `wpctl status` | PipeWire graph healthy, correct default sink |
| 8 | Bluetooth | Pair a device | Pairs and reconnects after reboot |
| 9 | Controller | Connect gamepad | Detected in Steam, inputs map correctly |
| 10 | Steam + Proton | Install & run one Windows game | Launches and renders correctly |
| 11 | MangoHud | `mangohud %command%` on that game | Overlay renders, sane FPS |
| 12 | GameMode | `gamemoded -s` while game runs | Reports active |
| 13 | gamescope session | Log out → select gamescope session | Boots to Steam Big Picture UI |
| 14 | ujust tooling | `ujust --choose` | Recipe list renders |
| 15 | Network | Wired + Wi-Fi | Link up, expected speeds |
| 16 | Suspend/resume | Suspend, wake | No GPU/audio breakage after wake |
| 17 | Update path | `bootc status` | Booted image + staged/rollback slots sane |

## Machine record

- CPU:
- Motherboard / chipset:
- RAM:
- Drives (which holds Windows / which gets SageOS):
- Monitors (model, resolution, refresh, VRR/HDR):
- Wi-Fi/BT chipset:
- Controllers / peripherals:

## Run log

| Date | Image | Result | Notes |
|---|---|---|---|
| | bazzite:stable (baseline) | | |
