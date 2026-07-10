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
