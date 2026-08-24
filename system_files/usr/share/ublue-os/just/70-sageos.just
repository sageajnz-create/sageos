# vim: set ft=make :
# SageOS ujust recipes. Imported via /usr/share/ublue-os/justfile
# (import line appended by build_files/scripts.d/40-just.sh).

# Run the SageOS health check (GPU, audio, gaming stack, image state)
[group("SageOS")]
sageos-doctor:
    /usr/libexec/sageos-doctor

# Show SageOS image identity and deployment status
[group("SageOS")]
sageos-version:
    @cat /etc/sageos-release
    @echo
    @rpm-ostree status --booted 2>/dev/null || bootc status 2>/dev/null || true

# Update everything now — the same run the automatic timer does
# (system image via bootc/rpm-ostree, then flatpaks)
[group("SageOS")]
sageos-update:
    @echo "Updating SageOS (image + flatpaks)..."
    @sudo uupd

# Roll back to the previous image, e.g. after a bad update.
# The booted deployment is pinned by sageos-pin.service, so this target
# is always the last image that booted successfully on this machine.
[group("SageOS")]
sageos-rollback:
    #!/bin/bash
    set -euo pipefail
    sudo rpm-ostree rollback
    echo
    echo "Rolled back. Reboot to enter the previous image:"
    echo "  systemctl reboot"
