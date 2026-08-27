# SageOS product and engineering plan

## Product promise

SageOS is an approachable, atomic desktop that makes gaming, Windows software,
AI, and deep customization understandable to non-experts. It should feel as
safe and guided as a mainstream consumer OS while retaining Linux ownership:
local-first operation, inspectable changes, rollback, and no required cloud
account.

The product is not "an AI chatbot preinstalled on Bazzite." The agent is a
permissioned control plane over documented, reversible system capabilities.
Every action must also remain available through normal UI or CLI workflows.

## Non-negotiable principles

1. **Local-first, cloud-optional.** Core desktop and configuration work
   offline. Frontier subscriptions and API keys are optional adapters.
2. **Capability detection, not hardware promises.** Detect CPU, GPU, RAM,
   storage, and model compatibility; recommend tested profiles and explain
   trade-offs before downloading models.
3. **Reversible by default.** Agent and UI changes produce a preview, an audit
   record, and an undo path. System-image rollback remains the final safety net.
4. **Secrets stay out of prompts and logs.** Store provider credentials in the
   desktop secret service; pass short-lived references to adapters.
5. **Compatibility claims are tested claims.** "Windows support" is a routed
   compatibility experience, not a guarantee that every Windows program runs.
6. **Stable core, replaceable providers.** UI and system contracts must not be
   coupled to one model runner, cloud vendor, or agent framework.
7. **Accessible without the agent.** Setup, recovery, accessibility, and
   privacy controls never depend on successful inference.

## Target architecture

### Sage Control Center

A native system application owns onboarding, updates and rollback, hardware
status, applications, gaming, Windows compatibility, AI providers and models,
privacy, personalization, backups, and diagnostics. It calls a small versioned
system service over D-Bus rather than invoking arbitrary privileged shell.

### Sage Agent

The assistant uses explicit tools exposed by the system service. Tool calls
declare required privilege, expected file changes, network use, and rollback
behavior. Read-only operations can run immediately; mutations require a clear
preview and confirmation appropriate to their impact. All calls are recorded
locally with secrets redacted.

The bundled `sageos` skill is the agent's maintained operating manual and tool
policy. It describes supported customization surfaces, diagnostics, safe
recipes, and recovery. It must not grant authority, embed secrets, or edit
vendor-owned files directly. Its behavior is contract-tested against the same
D-Bus/CLI API used by the Control Center.

### AI runtime broker

A user service provides one local OpenAI-compatible endpoint to applications
and routes requests to interchangeable backends. Initial support should target
one CPU-capable runner and one GPU-accelerated runner only after license,
sandboxing, packaging, and update review. The broker owns model discovery,
download verification, storage quotas, context limits, concurrency, and power
policy.

Hardware tiers are recommendations, not separate editions:

| Tier | Typical capability | Default behavior |
|---|---|---|
| Minimal | CPU-only, 8 GB RAM | Small quantized text model; no background load |
| Standard | 16 GB RAM or modest GPU | Mid-size quantized model, one active request |
| Performance | 32+ GB RAM or capable GPU | Larger models and optional multimodal tools |
| Cloud | Any supported device | User-selected subscription/API adapter |

No model is downloaded during installation without informed consent. Show
download size, expected RAM/VRAM, license, source, and a measured local speed
estimate. Encrypt or isolate conversation history and make retention visible.

### Windows compatibility center

Route software through the safest suitable path: native Linux/Flatpak first,
then Steam Proton for games, Bottles/Wine for applications, a Windows VM for
supported workloads, and dual boot for kernel anti-cheat or hardware-dependent
software. Import installers into per-app bottles, expose permissions and file
access, snapshot before risky changes, and maintain a tested compatibility
catalog. Never market universal compatibility or hide anti-cheat limitations.

### Customization framework

Use declarative user-owned profiles for appearance, shortcuts, panels,
applications, power behavior, and workflows. Profiles have a schema version,
dependencies, compatibility range, preview, export/import, and transactional
apply/rollback. Keep distribution defaults immutable; layer user overrides in
documented locations. This borrows Omarchy's discoverable commands and theme
bundles while adding GUI previews, validation, migrations, and undo history.

## Delivery phases

### Phase 6A — engineering foundation

- Define supported hardware and release channels (`stable`, `testing`).
- Add a single `just validate` gate and run it in CI.
- Add container structure tests for files, modes, services, policy, and ujust.
- Automate qcow2 boot, login, `sageos-doctor`, journal capture, and artifact
  publication; make failures reproducible locally. (implemented; awaiting the
  first green scheduled CI run)
- Add SBOM, vulnerability scanning, provenance, recovery-key documentation,
  and a security disclosure policy. (recovery and disclosure documentation
  done; build attestations and scanning remain)
- Resolve executable-bit inconsistency for shipped scripts and tests. (done:
  enforced by `tests/test-image-structure.sh`)

Exit: every pull request gets offline tests and an image build; scheduled CI
boots a VM and produces machine-readable health results.

### Phase 6B — consumer desktop foundation

- Build the Control Center shell and first-boot experience.
- Cover network, accounts, updates, rollback, apps, display, audio, privacy,
  diagnostics, and recovery without requiring a terminal.
- Establish accessibility, localization, telemetry opt-in, and UX test policy.
- Create branded defaults as a profile, not scattered configuration edits.

Exit: a new user can install, update, recover, and perform daily setup through
the GUI on the reference AMD machine and one Intel/NVIDIA test system.

### Phase 7 — customization platform

- Specify the profile schema and transactional apply engine.
- Ship themes, layout presets, keyboard shortcuts, export/import, and undo.
- Publish the versioned `sageos` CLI/D-Bus contract and bundled agent skill.
- Add signed community bundles with permissions and compatibility metadata;
  do not execute arbitrary theme scripts.

Exit: automated tests apply, migrate, export, import, and roll back every stock
profile, while the GUI and agent produce identical state changes.

### Phase 8 — local and frontier AI

- Prototype the runtime broker with benchmark-driven hardware detection.
- Ship model catalog metadata, verified downloads, quotas, uninstall, and
  offline mode before adding more backends.
- Add provider adapters for API keys and supported subscription sign-in flows
  only where vendors permit them; never scrape consumer sessions.
- Add permission prompts, tool audit log, prompt-injection boundaries, secret
  redaction, and destructive-action recovery tests.
- Expose a stable local endpoint for third-party applications.

Exit: each hardware tier has a tested model recommendation; local operation
works offline; cloud use is optional; red-team tests cannot silently mutate the
system or exfiltrate stored credentials.

### Phase 9 — Windows experience

- Build installer detection and guided Bottles/Proton flows.
- Add per-app prefixes, snapshots, file-association control, and uninstall.
- Add guided Windows VM creation with TPM, Secure Boot, shared folders, and
  resource recommendations; retain dual-boot guidance for incompatible titles.
- Maintain automated smoke apps and a public compatibility evidence format.

Exit: representative productivity apps and games pass install/run/update/
uninstall tests, and unsupported cases receive an honest routed alternative.

### Phase 10 — release and ecosystem

- Versioned ISO releases, checksums/signatures, mirrors, release notes, support
  lifetime, rollback drills, and documented key rotation.
- Hardware certification matrix across AMD, Intel, NVIDIA, laptops, handhelds,
  Wi-Fi/Bluetooth, docks, suspend, HDR/VRR, and common controllers.
- Crash reporting and diagnostics export are explicit opt-in and redact user
  data. Define contribution, moderation, and bundle review processes.

Exit: release candidates meet published security, recovery, accessibility,
compatibility, performance, and hardware gates.

## First three milestones

1. **Reliable VM gate:** structure-test the image and automatically boot the
   qcow2 in CI, run `sageos-doctor --json`, and archive journals.
2. **Control Center vertical slice:** hardware summary, update status, rollback,
   and diagnostics through a minimal D-Bus service with no AI dependency.
3. **Customization vertical slice:** one theme/layout profile applied through
   GUI, CLI, and a prototype `sageos` skill, with preview and undo.

AI runtime work begins after these contracts exist. That sequencing gives the
agent safe tools to use and gives users a complete non-AI recovery path.

## Decisions required before implementation

- Supported CPU architectures and minimum hardware for the first public build.
- Whether Plasma remains the long-term shell or SageOS owns additional shell
  components; avoid maintaining a desktop fork until product evidence demands it.
- Language/toolkit for Control Center and the system service.
- Initial local inference backend and model redistribution policy after license
  review; model weights should not be committed to this repository.
- Which frontier providers have supported authentication/API terms for an OS
  integration. Subscription access and API access must be treated separately.
- Definition of "Windows support" for the first release and the public test set.

## Current repository gaps found in the audit

- CI builds images but previously did not run ShellCheck or unit tests.
- Only deployment pinning has an offline unit test; doctor, Flatpak setup,
  signing policy, service enablement, and build stages are untested in isolation.
- Disk CI builds artifacts but does not boot or assert them automatically.
- The roadmap's phase statuses mix implementation and validation; use separate
  `built`, `VM-verified`, and `hardware-verified` fields going forward.
- The image is AMD-first and x86_64 in practice, while disk CI exposes arm64;
  supported architecture claims need an explicit decision and test matrix.
- The current signing policy protects the SageOS image path, but release
  provenance, SBOM, vulnerability response, key rotation, and recovery are not
  yet a complete supply-chain program.
