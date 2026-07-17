---
title: Network Architecture
document: Architecture
status: Active
created: 2026-07-17
updated: 2026-07-17
platform_version: v0.3.0
owner: GreenVenom
---

# Network Architecture

## Philosophy

Remote access is private by default.

---

## External Access

Windows Workstation

↓

Tailscale

↓

SSH

↓

Mac mini

---

## Internal Services

OpenClaw

↓

localhost

↓

Ollama

---

Docker Network

↓

Qdrant

↓

Monitoring

---

## Security Principles

- No public SSH
- No port forwarding
- Encrypted transport
- Least privilege
- Local service communication whenever possible

---

## Future

- Reverse proxy
- TLS certificates
- Service authentication

## Related documentation

- [Documentation map](../README.md)
