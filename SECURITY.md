# SageOS security policy

SageOS is pre-release software and does not yet have a supported stable release.
Security fixes currently target the latest image and the `main` branch only.

## Reporting a vulnerability

Do not open a public issue for a suspected vulnerability. Use GitHub's
**Security → Advisories → Report a vulnerability** flow for this repository.
Include the affected image digest or commit, reproduction steps, impact, and
any proposed mitigation. Remove credentials, personal data, and unrelated
system logs before attaching diagnostics.

If private vulnerability reporting is unavailable, contact the repository
owner privately and ask for a secure reporting channel. Do not include exploit
details in that first message.

## Response process

The project will acknowledge a report, reproduce and classify it, prepare a
fix, and coordinate disclosure with the reporter. No response-time or embargo
guarantee is offered before the first stable release. Confirmed issues and
affected versions will be documented in a GitHub Security Advisory.

Compromised signing credentials are handled using the emergency procedure in
[docs/signing-and-recovery.md](docs/signing-and-recovery.md).

## Scope

Reports about SageOS-owned image contents, build workflows, update/signature
policy, services, scripts, and future Control Center APIs are in scope. Issues
that reproduce unchanged on Bazzite, Fedora, Flatpak, or an upstream application
should normally be reported upstream; SageOS may still coordinate when its
defaults materially increase the impact.
