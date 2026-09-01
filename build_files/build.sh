#!/bin/bash
# SageOS build orchestrator.
# Runs inside the container build (see Containerfile). Overlays static files
# from system_files/, then executes every stage in scripts.d/ in numeric order.
# Add a new capability = drop a new NN-name.sh into scripts.d/. Keep stages
# idempotent and independent so they can be reordered or removed cleanly.

set -ouex pipefail

# Overlay static system files from the repo onto the image root
cp -avf /ctx/system_files/. /

# fedora-bootc already committed /usr/etc/containers/policy.json
# (insecureAcceptAnything). bootc install copies NEW /etc files into the
# ostree factory tree (cosign.pub) but keeps existing parent /usr/etc
# files. Replace that unsigned default so installed systems get
# sigstoreSigned. Do not add system_files/usr/etc — bootc lint and
# tests/test-image-structure.sh reserve that path for generated defaults.
if [[ -f /etc/containers/policy.json ]]; then
    install -D -m 0644 /etc/containers/policy.json /usr/etc/containers/policy.json
fi

# Executable bits can be lost by Windows checkouts — enforce them here for
# anything we ship that systemd or users execute directly.
chmod 0755 /usr/libexec/sageos-* 2>/dev/null || true

# Run build stages in order
for stage in /ctx/scripts.d/*.sh; do
    echo "==> Running stage: ${stage}"
    # invoked via bash so builds don't depend on the executable bit,
    # which git-on-Windows does not preserve
    bash "${stage}"
done
