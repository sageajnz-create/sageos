#!/bin/bash
# Stage 10: RPM packages layered into the OS image.
#
# Policy (keep this list SMALL — it is the whole point of the architecture):
#   - GUI apps            -> Flatpak (user-installed or default-flatpaks list, Phase 3)
#   - CLI tools           -> Homebrew
#   - Dev environments    -> Distrobox/toolbox
#   - Layer an RPM here ONLY if it must be part of the OS itself:
#     kernel modules, system daemons, udev rules, session components.
#
# Fedora + RPM Fusion repos are enabled in the Bazzite base.

set -ouex pipefail

dnf5 install -y \
    tmux \
    vulkan-tools \
    glx-utils \
    libva-utils
# vulkan-tools/glx-utils/libva-utils: vulkaninfo, glxinfo, vainfo — required
# by docs/phase*-validation.md checklists; not present in the Bazzite base.

# ── Reserved for later phases (uncomment when the phase lands) ──
# Phase 4 (gaming extras not already in Bazzite): none expected — Bazzite
#   ships Steam, gamescope, MangoHud, GameMode, vkBasalt already.
# Phase 5 (virtualization fallback path):
# dnf5 install -y virt-manager libvirt-daemon-kvm qemu-kvm virtiofsd
# systemctl enable libvirtd.socket
