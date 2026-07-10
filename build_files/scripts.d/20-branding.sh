#!/bin/bash
# Stage 20: SageOS identity.
#
# Deliberately conservative: we change PRETTY_NAME only. ID, ID_LIKE, VARIANT
# and VARIANT_ID stay "bazzite"/"fedora" so ujust recipes, update tooling
# (uupd), and anything that keys off os-release keeps working. Deeper
# rebranding (logos, Plasma theme, boot splash) is Phase 6 polish.

set -ouex pipefail

sed -i 's|^PRETTY_NAME=.*|PRETTY_NAME="SageOS 0.1 (built on Bazzite)"|' /usr/lib/os-release
