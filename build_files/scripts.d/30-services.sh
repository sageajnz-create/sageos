#!/bin/bash
# Stage 30: systemd units enabled by default in the image.
# Enable here (not at runtime) so every install gets identical service state.

set -ouex pipefail

# Podman API socket — foundation for container tooling and agent workflows
systemctl enable podman.socket

# First-boot/post-update installer for SageOS default flatpaks
# (unit + script + list live in system_files/)
systemctl enable sageos-flatpak-setup.service
