# Phase 4 validation — gaming stack & compatibility layers

Real hardware required for anything past #3. Prereq: phases 1–3 validated.

| # | Check | Method | Pass criteria |
|---|---|---|---|
| 1 | Doctor | `ujust sageos-doctor` | 0 failures (warnings allowed in VM) |
| 2 | ujust integration | `ujust --choose` | SageOS group with doctor/version recipes listed |
| 3 | Launchers installed | `flatpak list --system` | Heroic, Lutris, Bottles, Protontricks present after setup service runs |
| 4 | Steam + official Proton | install & run a known-good Windows title | runs; check protondb baseline |
| 5 | Proton-GE path | ProtonUp-Qt → install latest GE → restart Steam | GE selectable in title Compatibility menu; title runs with it |
| 6 | EAC/BattlEye runtime | run one opted-in AC title (e.g. Apex) | reaches multiplayer without AC error |
| 7 | Heroic | log into Epic or GOG, install small title | downloads, launches under Proton/Wine-GE |
| 8 | Lutris | one install-script title (e.g. Battle.net) | script completes, launches |
| 9 | Bottles | create app bottle, install a simple Windows utility | runs |
| 10 | Protontricks | `flatpak run com.github.Matoking.protontricks --list` | enumerates Steam prefixes |
| 11 | MangoHud | `mangohud %command%` on any title | overlay renders |
| 12 | GameMode | `gamemoded -s` during a title | "gamemode is active" |
| 13 | gamescope nested | wrap a title with `gamescope -- %command%` | renders; try `--hdr-enabled` if monitor supports |
| 14 | Boot-to-Windows | `ujust setup-boot-windows-steam` → use Steam button | reboots into Windows cleanly, and back |
| 15 | Rollback safety | `sudo bootc rollback` after this image; boot previous | gaming stack still intact on previous image |

## Run log

| Date | Image tag | Check # | Result | Notes |
|---|---|---|---|---|
| | | | | |
