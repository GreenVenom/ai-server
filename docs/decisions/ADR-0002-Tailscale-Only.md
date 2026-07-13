---
title: Tailscale Only Remote Access
status: Accepted
date: 2026-07-12
decision_id: ADR-0002
supersedes:
superseded_by:
---

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
