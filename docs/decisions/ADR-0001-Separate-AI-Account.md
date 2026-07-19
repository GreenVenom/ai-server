---
title: ADR-0001 - Separate AI Account
document: ADR
status: Accepted
created: 2026-07-17
updated: 2026-07-18
platform_version: v0.3.0
owner: GreenVenom
decision_id: ADR-0001
milestone: M01
supersedes:
superseded_by:
date: 2026-07-12
---

# ADR-0001 - Separate AI Account


## Context

The server will host AI workloads while remaining remotely administered.

AI services should not execute with administrator privileges.

---

## Decision

Create two accounts.

Admin

- System administration
- Software installation
- OS maintenance

AI

- Standard user
- Runs Ollama
- Runs OpenClaw
- SSH login
- Owns AI data

---

## Consequences

### Positive

- Principle of least privilege
- Better isolation
- Reduced risk if AI tools are compromised

### Negative

- Software updates require the admin account.

## Related documentation

- [Documentation map](../README.md)
