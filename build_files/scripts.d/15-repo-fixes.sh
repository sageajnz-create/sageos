#!/bin/bash
# Stage 15: repo hygiene fixes on top of the base image.
#
# terra-mesa: Bazzite's own build disables this repo (Containerfile:
# `setopt "terra-mesa".enabled=false`), but the shipped image has enabled=1 —
# a later terra-release-mesa package update rewrites the repo file. An ENABLED
# repo whose gpgkey is a file:// path breaks bootc-image-builder's
# anaconda-iso depsolve, because bib resolves gpgkey against the BUILDER
# container's filesystem, which has no Terra keys (the key file does exist in
# our image — verified 2026-07-10 in a booted VM). Restoring the intended
# disabled state fixes the ISO build; this stage runs after the base, so
# nothing rewrites it again.

set -ouex pipefail

sed -i 's/^enabled=1/enabled=0/' /etc/yum.repos.d/terra-mesa.repo
grep -H "^enabled=" /etc/yum.repos.d/terra-mesa.repo
