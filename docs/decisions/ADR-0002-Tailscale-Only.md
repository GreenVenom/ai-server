---
title: ADR-0002 - Tailscale Only Remote Access
document: ADR
status: Accepted
created: 2026-07-17
updated: 2026-07-17
platform_version: v0.3.0
owner: GreenVenom
decision_id: ADR-0002
supersedes:
superseded_by:
date: 2026-07-12
---

# ADR-0002 - Tailscale Only Remote Access


## Context

The server must be accessible remotely while minimizing exposure to the public Internet.

---

## Decision

Remote administration will occur exclusively through Tailscale.

SSH will not be exposed to the public Internet.

---

## Consequences

### Positive

- No port forwarding
- Encrypted mesh VPN
- Simpler firewall configuration
- Reduced attack surface

### Negative

- Requires Tailscale availability.
- Requires Tailscale authentication.

## Related documentation

- [Documentation map](../README.md)
