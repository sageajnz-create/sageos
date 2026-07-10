# Installing SageOS (dual-boot with Windows)

## Disk strategy

**Strongly preferred: a dedicated drive for SageOS.** Windows feature updates
have a history of rewriting EFI boot entries; a separate drive with its own
EFI System Partition makes the two OSes fully independent — either drive can
die, be wiped, or be reinstalled without touching the other.

Target layout (SageOS drive, handled automatically by the installer):

| Partition | Size | Purpose |
|---|---|---|
| EFI System Partition | 1 GiB | systemd-boot/GRUB, shim (Secure Boot) |
| /boot | 1 GiB | kernels, ostree bootloader state |
| LUKS2 → Btrfs | rest | subvolumes: `root`, `home`, `var` |

Same-drive dual boot works too (shrink the Windows partition, share the ESP)
but you accept the Windows-update-clobbers-bootloader risk. Keep a SageOS USB
stick around to repair boot entries if it happens.

## Recommended install path (Phase 2–6)

1. Back up anything irreplaceable on the Windows side. Turn off BitLocker
   auto-suspend traps: note your BitLocker recovery key first.
2. Download the **Bazzite (KDE, desktop)** ISO from bazzite.gg and write it to
   USB.
3. Install to the dedicated drive. Enable disk encryption in the installer if
   wanted (recommended). Leave Secure Boot ON — enroll the uBlue MOK key when
   prompted (one-time; password is documented by Bazzite as `universalblue`).
4. Boot into Bazzite, then rebase to SageOS:

   ```bash
   sudo bootc switch ghcr.io/sageajnz-create/sageos:latest
   systemctl reboot
   ```

5. Verify: `cat /etc/sageos-release` and `bootc status` should show the
   SageOS image as the booted deployment.

Choosing which OS to boot: use the firmware boot menu (F8/F11/F12 depending on
board) or set the SageOS drive first — GRUB lists Windows automatically when
its ESP is detectable.

## Why not the custom ISO yet?

CI can already build a SageOS installer ISO (`build-disk.yml` →
`anaconda-iso`). It works, but the stock Bazzite ISO is more battle-tested for
interactive partitioning on real hardware. The custom ISO becomes the primary
artifact in Phase 7 once we've validated it in a VM and on metal.

## Rollback / recovery

- Previous deployment: GRUB menu entry, or `sudo bootc rollback` (Bazzite base
  also supports `rpm-ostree rollback`).
- Pin a known-good deployment so updates never garbage-collect it:
  `sudo ostree admin pin 0`
- Nuclear option: reinstall from ISO and `bootc switch` again — `/home` is on
  its own subvolume; the OS is disposable by design.
