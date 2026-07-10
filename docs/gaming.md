# SageOS gaming & Windows compatibility

## The compatibility ladder

Work down this list; stop at the first rung that works.

| Rung | Tool | Use for | Notes |
|---|---|---|---|
| 1 | **Steam + Proton** (native) | Steam games | Default. Check protondb.com for per-title tweaks. |
| 2 | **Proton-GE** via ProtonUp-Qt (in base) | Steam games needing newer codecs/patches | Install GE build → restart Steam → per-title Compatibility setting. |
| 3 | **Heroic** (flatpak) | Epic, GOG, Amazon libraries | Uses same Proton/Wine-GE runners. |
| 4 | **Lutris** (flatpak) | Everything else with an installer script (Battle.net, emulators, standalone) | Community install scripts do the prefix surgery for you. |
| 5 | **Bottles** (flatpak) | Non-game Windows apps | Isolated prefixes; good for one-off utilities. |
| 6 | **Protontricks** (flatpak) | Fixing rungs 1–2 | winetricks against a specific Steam prefix. |
| 7 | **Windows VM** — `ujust setup-virtualization` (in base) | Apps that defeat Wine (Office add-ins, some Adobe, firmware tools) | KVM/QEMU/virt-manager. GPU-heavy apps will be slow without a second passthrough GPU. |
| 8 | **Reboot to Windows** — `ujust setup-boot-windows-steam` (in base) | Kernel anti-cheat titles, final fallback | Adds a "boot Windows" button inside Steam. This is the honest answer for rung-8 titles. |

## Anti-cheat: the hard truth

- **Works**: titles whose devs enabled the EAC/BattlEye Proton runtimes
  (Apex, Elden Ring co-op, DBD, many more).
- **Never works on Linux**: kernel-level anti-cheat and titles whose devs
  opted out — as of 2026-07 this includes Valorant/LoL (Vanguard), Fortnite,
  Destiny 2 (bannable!), Rainbow Six Siege, most COD/Battlefield.
- **VMs are NOT a workaround**: anti-cheat detects virtualization; several
  vendors issue bans for it. Rung 8 exists for a reason.
- Live status — always check, lists rot:
  [areweanticheatyet.com](https://areweanticheatyet.com) and
  [protondb.com](https://www.protondb.com).

## Shader cache strategy

Nothing to configure on SageOS — this is documentation of *why it's already
right*:

- RADV's graphics-pipeline-library support means Proton/DXVK compiles most
  pipelines on the fly without stutter; the days of mandatory pre-caching are
  over on AMD.
- Keep Steam's "Shader Pre-Caching" + background processing **on** (default);
  it still helps first-launch times on Vulkan-native titles.
- Caches live under the Steam library and `~/.cache/{mesa_shader_cache*,radv_builtin_shaders*}`
  on the Btrfs `home` subvolume — they survive OS updates and rollbacks by design.
- After a Mesa major bump (visible in image update notes), first launches
  recompile; this is expected, not a regression.

## Overlays & performance

- MangoHud: launch option `mangohud %command%` (native + flatpak Vulkan layer
  both shipped in base).
- GameMode: automatic for Steam games via Proton; force with
  `gamemoderun %command%`. Verify with `gamemoded -s` while a game runs.
- gamescope (nested): `gamescope -W 2560 -H 1440 -r 165 --hdr-enabled -- %command%`
  for per-title HDR/scaling/frame-limit control on the desktop session.

## Per-title log

Track your own library here as you validate; this is the data that will tell
us whether Phase 6 tuning actually moves anything.

| Title | Store | Rung | Proton version | Result | Notes |
|---|---|---|---|---|---|
| | | | | | |

## macOS (experimental, expectations set low)

Not a supported feature. Realistic options, in order of usefulness:
1. macOS VM (OSX-KVM/quickemu) — CPU-only graphics is fine for Xcode-ish
   tasks; note Apple's EULA licenses macOS for Apple hardware only.
2. Navi 23 (our 6650 XT) has real macOS drivers, so single-GPU passthrough is
   *technically plausible* — a research project, not a roadmap item.
3. Darling — CLI-level macOS binaries only. No GUI app support worth claiming.
