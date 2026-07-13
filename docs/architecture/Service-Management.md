---
title: Service Management
status: Active
---

## Service Management

### Philosophy

Each service should have:

- One owner
- One startup method
- One configuration location
- One logging location
- One verification procedure

---

### Native Services

Managed through launchd.

Examples

- Ollama
- OpenClaw

---

### Containerized Services

Managed through Docker Compose.

Examples

- Qdrant
- Grafana
- Prometheus
- Uptime Kuma

---

### Lifecycle

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

### Operational Standards

Every service must include:

- Configuration
- Logging
- Health check
- Runbook
- Verification
