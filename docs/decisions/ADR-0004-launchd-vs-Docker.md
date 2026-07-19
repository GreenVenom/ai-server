---
title: ADR-0004 - launchd for Native Services
document: ADR
status: Accepted
created: 2026-07-17
updated: 2026-07-18
platform_version: v0.3.0
owner: GreenVenom
decision_id: ADR-0004
milestone: M01
supersedes:
superseded_by:
date: 2026-07-12
---

# ADR-0004 - launchd for Native Services


## Context

Some services integrate directly with macOS while others are better suited to containers.

---

## Decision

Native macOS services

- Ollama
- OpenClaw

will be managed by launchd.

Containerized infrastructure

- Qdrant
- Grafana
- Prometheus
- Uptime Kuma

will use Docker Compose.

---

## Consequences

### Positive

- Better Apple Silicon performance
- Native startup
- Automatic restart
- Simpler resource management

### Negative

Two service management systems must be understood.

## Related documentation

- [Documentation map](../README.md)
