# SageOS development environment

## Supported development host

Use a Linux host with Podman and KVM. Building the bootc image needs network
access and substantial storage; bootable image builds additionally need
rootful Podman. The repository's fast checks are offline and unprivileged.

### macOS fast checks

macOS can run the Level 0 validation gate even though image and VM builds still
require Linux. Install the test dependencies with Homebrew and put GNU
coreutils ahead of the macOS utilities for the test process:

```bash
brew install bash coreutils just shellcheck
PATH="$(brew --prefix coreutils)/libexec/gnubin:$PATH" just validate
```

`shfmt` is only required by `just format`; `cosign` is only required for manual
signature verification and key-management work.

For Arch Linux or Omarchy:

```bash
omarchy pkg add just shellcheck shfmt podman qemu-base libvirt swtpm edk2-ovmf dnsmasq
sudo usermod -aG libvirt,kvm "$USER"
sudo systemctl enable --now libvirtd.service
sudo modprobe kvm_amd       # AMD CPU; use kvm_intel on Intel
```

Log out and back in after changing group membership. A reboot is the simplest
way to both refresh groups and confirm that KVM loads at boot.

## Test levels

Run the cheapest level that can catch the change, then every lower level:

| Level | Command | Purpose |
|---|---|---|
| 0 | `just validate` | Just syntax, ShellCheck, offline behavior and image-structure tests |
| 1 | `just build`, then `just validate-image` | Build, bootc-lint, and contract-test the OCI image |
| 2 | `just rebuild-qcow2` | Build a fresh bootable VM disk |
| 3 | `just run-vm-qcow2` | Interactive VM validation and `sageos-doctor` |
| 4 | Hardware checklist | GPU, audio, controllers, suspend, Windows dual boot. Collect digest/PCI/firmware/kernel and fill [evidence/hardware/](evidence/hardware/README.md) |

Level 0 is required for every pull request. Image CI supplies Level 1. Disk CI
supplies Level 2 and runs `just validate-vm-qcow2` nightly for an automated
serial-console boot, machine-readable doctor report, and boot journal. The
same command can validate an existing local `output/qcow2/disk.qcow2`.

## Verify the host after reboot

```bash
groups | grep -E '(^| )(kvm|libvirt)( |$)'
test -r /dev/kvm && test -w /dev/kvm
podman info
systemctl is-active libvirtd.service
just validate
```

The Codex workspace may itself run inside a restricted container. In that
case `/dev/kvm`, the host systemd bus, and the host Podman storage may not be
visible even when the host is configured correctly. Run image and VM commands
from a normal host terminal.
