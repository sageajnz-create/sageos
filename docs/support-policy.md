# Hardware and release support policy

SageOS is pre-release software. This document separates configurations the
project actively validates from configurations that may work through Bazzite
or Fedora but are not yet SageOS release claims.

## Release channels

| Channel | Image reference | Contract |
|---|---|---|
| Testing | `ghcr.io/sageajnz-create/sageos:latest` | Built from every successful `main` commit; automated image checks and nightly VM boot gate; may contain regressions |
| Stable | `ghcr.io/sageajnz-create/sageos:stable` | Reserved for digest promotion after published release gates; not published during the pre-release phase |
| Versioned | `ghcr.io/sageajnz-create/sageos:vX.Y.Z` | Reserved immutable release alias pointing to the same approved digest as `stable` |

`latest` is retained as the testing tag for compatibility with existing
installs. It does not mean stable. Stable releases must promote an already
built and tested digest; they must never rebuild source under a release tag.
Promotion automation and versioned releases belong to Phase 10. Until then,
all installs are testing installs.

Downgrading from testing to stable requires an explicit `bootc switch` once a
stable channel exists. The Control Center must show the channel, digest, and
rollback consequence before changing it.

## Supported architecture and firmware

- **Architecture:** x86_64 only.
- **Boot:** UEFI. Legacy BIOS is not a release target.
- **Storage:** 64 GB minimum practical disk for installation, updates, one
  pinned rollback deployment, Flatpaks, and user data. More is strongly
  recommended for games. The 20 GiB qcow2 root is CI-only.
- **Memory:** 8 GB minimum for the desktop; 16 GB recommended for gaming and
  future local AI features. Model-specific requirements will be published
  separately and do not change the OS minimum.
- **Virtualization:** QEMU/KVM qcow2 is the automated smoke-test platform, not
  a claim of complete virtual-machine feature support.

## Graphics and device status

| Hardware | Current status | Release claim |
|---|---|---|
| AMD Radeon using Mesa RADV | Primary target | Automated software checks; RX 6650 XT packet template exists, hardware validation still required |
| Intel integrated/discrete graphics | Expected through the Bazzite base | Not SageOS hardware-verified yet |
| NVIDIA GPUs | Expected through Bazzite's supported NVIDIA path | Not SageOS hardware-verified yet; no blanket hybrid-laptop claim |
| Handhelds, HDR/VRR, docks, suspend | Candidate configurations | No support claim until entered in the hardware matrix with evidence |

Wi-Fi, Bluetooth, audio, controllers, secure boot, suspend, and display
features inherit broad upstream support, but SageOS only labels them verified
after completing the repository hardware checklists on a recorded machine.

## Evidence labels

Feature and hardware status use three distinct labels:

- **Built:** present in the image or configuration and covered by offline or
  structure tests.
- **VM-verified:** exercised successfully in the automated or documented
  qcow2 environment.
- **Hardware-verified:** exercised on identified physical hardware with the
  applicable validation checklist and date recorded.

Absence from the hardware-verified matrix means unverified, not necessarily
broken. Compatibility reports must include the image digest, hardware IDs,
firmware version, kernel version, and checklist result.

Packets and collection commands live in
[evidence/hardware/](evidence/hardware/README.md). The RX 6650 XT template is
empty until a physical run is recorded. Intel and NVIDIA remain unverified
until equivalent packets exist.
