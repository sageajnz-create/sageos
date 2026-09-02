# Hardware evidence packets

This folder is the archive for **physical** SageOS hardware validation. It
exists so a later run on real machines can be recorded without guessing.

Nothing here is a completed hardware claim. Phase 6A VM evidence lives in
[../phase6a/](../phase6a/README.md). Supply-chain triage policy is in
[../../supply-chain.md](../../supply-chain.md). Phase 6B / Control Center is
**not** this work.

The checklists to execute are unchanged:

- [../../phase1-validation.md](../../phase1-validation.md) — baseline machine + RADV/session/audio/input
- [../../phase3-validation.md](../../phase3-validation.md) — desktop, graphics, input, audio
- [../../phase4-validation.md](../../phase4-validation.md) — gaming stack, Proton, rollback-under-use
- [../../phase5-validation.md](../../phase5-validation.md) — updates, pin, signed image, rollback recipes

## Purpose

[support-policy.md](../../support-policy.md) only labels a configuration
**hardware-verified** after an identified machine is exercised with those
checklists and a date is recorded. Compatibility reports must include:

| Required field | Why |
|---|---|
| Immutable image digest (`sha256:…`) | `latest` moves; a tag is not evidence |
| PCI IDs (`lspci -nn`) | Identifies GPU, audio, network, USB, Bluetooth |
| Firmware (system BIOS/UEFI; GPU fw if visible) | Separates OS bugs from board/GPU firmware |
| Kernel (`uname -r`) | Mesa/RADV results are kernel-bound |
| Display / audio / controller results | The hardware-sensitive Phase 1/3/4 checks |
| Rollback result | Proves the previous image still boots and plays |
| Known limitations | Honest unverified or failed items |
| Phase 1 machine record | CPU, motherboard, RAM, drives, monitors, Wi-Fi/BT, peripherals |

Fill those fields from commands on the machine. **Do not invent PCI IDs,
digests, firmware strings, or pass/fail results.** Leave a cell empty rather
than guessing. Do not copy Phase 6A qcow2 doctor output into a hardware
packet and call it metal.

## Packets

| Packet | Hardware | Status |
|---|---|---|
| [amd-rx6650xt/](amd-rx6650xt/TEMPLATE.md) | AMD CPU + Radeon RX 6650 XT (Navi 23) — the reference machine | **Template only.** Not filled. Next physical work is filling this packet. |
| *(none yet)* | Intel integrated or discrete graphics | **Unverified.** Do not treat Bazzite inheritance as a SageOS hardware claim. |
| *(none yet)* | NVIDIA GPUs (including hybrid laptops) | **Unverified.** No blanket NVIDIA or hybrid-laptop claim until an equivalent packet exists. |

Intel and NVIDIA remain unverified until someone adds an equivalent packet
under this folder (same required fields, same phase checklists) and fills it
from a real run. Absence of a packet means unverified, not broken.

Handhelds, docks, HDR/VRR, and suspend stay candidate configurations until
they appear in a filled packet. See the support-policy matrix.

## How to collect identity (copy-paste)

Run these on the **booted SageOS install** (or stock Bazzite for the Phase 1
baseline). Paste the output into the packet. Prefer the immutable digest of
the *booted* deployment, not the moving `latest` tag.

```bash
# --- Image digest (immutable) ---
bootc status
rpm-ostree status --booted
cat /etc/sageos-release

# Optional: print sha256 strings so you can copy the booted digest.
# Confirm it against `bootc status` / `rpm-ostree status` above; do not pick
# a staged or previous deployment by accident.
bootc status --format json 2>/dev/null | grep -oE 'sha256:[0-9a-f]{64}' || true
rpm-ostree status --json 2>/dev/null | grep -oE 'sha256:[0-9a-f]{64}' || true
```

Verify that digest (from a machine that has `cosign` and this repo's
`cosign.pub`) using the commands in
[../../supply-chain.md](../../supply-chain.md#verifying-an-image). Record
the digest in the packet even if verification is done later.

```bash
# --- PCI IDs ---
lspci -nn
lspci -nnk
```

Paste at least VGA/Display/3D, Audio, Network/Ethernet/Wi-Fi, USB, and
Bluetooth lines. Keep the `[vendor:device]` brackets from `lspci -nn`.

```bash
# --- Firmware ---
for f in bios_vendor bios_version bios_date board_vendor board_name product_name sys_vendor; do
    printf '%s=%s\n' "$f" "$(cat /sys/class/dmi/id/$f 2>/dev/null || echo unavailable)"
done
fwupdmgr get-devices 2>/dev/null || true
journalctl -k -b | grep -iE 'amdgpu.*(firmware|fw|psp|smu|vbios)' || true
```

```bash
# --- Kernel ---
uname -r
uname -a
```

```bash
# --- Quick doctor snapshot (optional attachment) ---
ujust sageos-doctor
# or: /usr/libexec/sageos-doctor --json
```

Do not commit large journals, fwupd dumps, firmware blobs, or home-directory
paths that identify a person. The packet wants the short identity fields and
pass/fail notes.

## How to run the checklists

1. Collect identity (commands above) **before** changing the image.
2. Phase 1 on stock Bazzite if this is a new machine, then again after
   `bootc switch` to SageOS. See [../../install.md](../../install.md).
3. Phase 3 on the SageOS image (GPU/display/audio need metal).
4. Phase 4 on metal for anything past the structure checks.
5. Phase 5 can be VM-checked, but still record digest/kernel on the AMD box
   when that is the machine under test. Include the rollback recipe result.
6. Copy [amd-rx6650xt/TEMPLATE.md](amd-rx6650xt/TEMPLATE.md) to a dated file
   in the same folder, **or** fill the template in place. Leave unused rows
   empty.

The next physical work is filling the AMD packet on the reference machine.
Do not start Phase 6B in the same change.
