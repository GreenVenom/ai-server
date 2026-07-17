---
title: Service Management
document: Architecture
status: Active
created: 2026-07-17
updated: 2026-07-17
platform_version: v0.3.0
owner: GreenVenom
---

# Service Management

## Philosophy

Each service should have:

- One owner
- One startup method
- One configuration location
- One logging location
- One verification procedure

---

## Native Services

Managed through launchd.

Examples

- Ollama
- OpenClaw

---

## Containerized Services

Managed through Docker Compose.

Examples

- Qdrant
- Grafana
- Prometheus
- Uptime Kuma

---

## Lifecycle

Install

↓

Configure

↓

Validate

↓

Monitor

↓

Update

↓

Retire

---

## Operational Standards

Every service must include:

- Configuration
- Logging
- Health check
- Runbook
- Verification

## Related documentation

- [Documentation map](../README.md)
