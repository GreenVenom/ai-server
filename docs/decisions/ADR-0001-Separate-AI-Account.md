---
title: Separate AI Account
status: Accepted
date: 2026-07-12
---

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
