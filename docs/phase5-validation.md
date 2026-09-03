# Phase 5 validation — system services, rollback & update policy

Mostly VM-checkable; nothing here strictly needs real hardware. Prereq:
phases 1–4 validated. When this run is on the reference AMD machine, still
record digest / PCI / firmware / kernel in
[evidence/hardware/amd-rx6650xt/TEMPLATE.md](evidence/hardware/amd-rx6650xt/TEMPLATE.md)
([collection commands](evidence/hardware/README.md)).

| # | Check | Method | Pass criteria |
|---|---|---|---|
| 1 | Doctor | `ujust sageos-doctor` | 0 failures; "Updates & integrity" section all PASS or expected WARN |
| 2 | ujust integration | `ujust --choose` | SageOS group now lists update and rollback recipes |
| 3 | Update timer armed | `systemctl status uupd.timer` | enabled, active, next trigger scheduled |
| 4 | No double-update path | `grep AutomaticUpdatePolicy /etc/rpm-ostreed.conf` | `none` (uupd owns updates) |
| 5 | Signature enforcement live | `sudo ujust sageos-update` (or wait for timer) | update pulls succeed — image is signed with our key |
| 6 | Tamper rejection | push an unsigned image tag to the same repo, point bootc at it, try to pull | pull rejected with signature verification error |
| 7 | Pin service ran | `systemctl status sageos-pin.service` | active (exited), no errors in journal |
| 8 | Booted deployment pinned | `rpm-ostree status` | booted entry shows pinned |
| 9 | Pin survives an update | apply an update, reboot into new deployment | old pin dropped, new booted deployment now the single pinned one |
| 10 | Rollback recipe | `ujust sageos-rollback`, then `systemctl reboot` | boots previous image; gaming stack intact |
| 11 | Greenboot safety net | `systemctl status greenboot-healthcheck` | enabled; on failed health check, rollback trigger fires (may simulate by masking a critical unit) |

## Run log

| Date | Image tag | Digest | PCI IDs | Firmware | Kernel | Check # | Result | Notes |
|---|---|---|---|---|---|---|---|---|
| | | | | | | | | |
