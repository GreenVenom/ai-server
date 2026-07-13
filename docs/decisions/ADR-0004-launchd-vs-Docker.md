---
title: launchd for Native Services
status: Accepted
date: 2026-07-12
---

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
