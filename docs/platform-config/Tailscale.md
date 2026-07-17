---
title: Tailscale Configuration
document: Configuration
status: Active
created: 2026-07-17
updated: 2026-07-17
platform_version: v0.3.0
owner: GreenVenom
---

# Tailscale Configuration


## Tailscale

### Purpose

Provides secure remote connectivity to the Personal AI Platform.

---

## Installation

Official macOS application.

---

## Authentication

GitHub account.

---

## Remote Access

SSH

Git

Administration

---

## Security

No public SSH.

No port forwarding.

No exposed AI services.

---

## Verification

```bash
tailscale status
```

```bash
tailscale ping <client>
```

---

## Usage

Primary workstation connects through Tailscale.

SSH uses Ed25519 authentication.

---

## Recovery

1. Install Tailscale.
2. Authenticate.
3. Enable SSH.
4. Verify connectivity.

## Related documentation

- [Documentation map](../README.md)
