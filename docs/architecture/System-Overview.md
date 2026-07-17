---
title: System Overview
document: Architecture
status: Active
created: 2026-07-17
updated: 2026-07-17
platform_version: v0.3.0
owner: Personal AI Platform maintainers
---

# System Overview

## Mission

Provide a secure, local-first AI platform for development, knowledge management, and automation while minimizing dependence on cloud-hosted AI services.

---

## Platform Objectives

- Local LLM inference
- Obsidian integration
- Knowledge retrieval
- AI-assisted software development
- Personal automation
- Future extensibility

---

## High-Level Architecture

```text
Windows Workstation
        │
SSH / Tailscale
        │
──────────────────────────────
Mac mini M4 Pro
──────────────────────────────
        │
launchd
        │
──────────────────────────────
Native Services
──────────────────────────────
Ollama
OpenClaw
Future Services
        │
──────────────────────────────
Docker Compose
──────────────────────────────
Qdrant
Grafana
Prometheus
Uptime Kuma
Future Infrastructure
```

---

## Design Principles

- Local-first
- Native performance
- Separation of responsibilities
- Reproducibility
- Operational simplicity

---

## Future Components

- MCP Servers
- Backup services
- Monitoring
- Automation workflows
- Disaster recovery
- Future cloud providers

## Related documentation

- [Documentation map](../README.md)
