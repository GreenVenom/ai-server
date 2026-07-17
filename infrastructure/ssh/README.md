---
title: SSH Configuration
document: Reference
status: Active
created: 2026-07-17
updated: 2026-07-17
platform_version: v0.3.0
owner: Personal AI Platform maintainers
---

# SSH Configuration

## Purpose

Provides secure remote administration of the AI server.

## Authentication

- Ed25519 keys
- Password login disabled
- Root login disabled

## Network

SSH is only accessed through Tailscale.

## Allowed User

openclaw is the only user allowed to log in via SSH.

## Key Rotation

1. Generate a new key.
2. Add the new public key to authorized_keys.
3. Verify login.
4. Remove the old key.

## Related documentation

- [Documentation map](../../docs/README.md)
