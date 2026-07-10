# Build context stage: scripts + system files are bind-mounted into the build,
# never copied into the final image.
FROM scratch AS ctx
COPY build_files /
COPY system_files /system_files

# ── SageOS base ──────────────────────────────────────────────────────────────
# Bazzite (KDE, desktop) = Fedora Atomic + uBlue hardware/codec layer + gaming
# stack (Steam, gamescope-session, fsync kernel, HDR, controller support).
# The digest pin makes every build reproducible; Renovate bumps it via PRs, so
# base updates arrive as reviewable diffs instead of silent drift.
FROM ghcr.io/ublue-os/bazzite:stable@sha256:b923f92d5a5b59eb992e269383eba2744601052da9d3d1595f76e79aa6ce2df0

# Run all build stages (see build_files/build.sh + build_files/scripts.d/).
# /var/cache and /var/log are cache mounts so dnf metadata survives between
# builds without ending up in the image; /tmp is tmpfs for the same reason.
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    bash /ctx/build.sh

# Fail the build if the result violates bootc image requirements.
RUN bootc container lint
