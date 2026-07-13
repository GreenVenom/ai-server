---
title: Personal AI Server
status: Active Development
version: 0.1.0
last_updated: 2026-07-12
owner: GreenVenom
---

## Personal AI Server

> A local-first AI platform built on a Mac mini M4 Pro, designed to provide secure, reproducible, and maintainable AI infrastructure while minimizing dependence on cloud-hosted AI services.

---

## Vision

The goal of this project is to build a production-quality personal AI platform capable of supporting:

- Local Large Language Models
- AI-assisted software development
- Obsidian knowledge management
- Retrieval-Augmented Generation (RAG)
- Personal automation
- MCP server integrations
- Long-term maintainability

The platform is designed with a strong emphasis on:

- Local-first AI
- Security by default
- Infrastructure as Code
- Documentation as Code
- Reproducible deployments
- Modular architecture

---

## Hardware

| Component | Specification |
| --------- | --------------- |
| Platform | Mac mini (2024) |
| Processor | Apple M4 Pro |
| Memory | 24 GB Unified Memory |
| Storage | 512 GB SSD |

---

## Current Project Status

| Milestone | Status |
| --------- | ------ |
| M01 – Foundation | ✅ Complete |
| M02 – AI Runtime Layer | 🚧 In Progress |
| M03 – OpenClaw Platform | ⏳ Planned |
| M04 – Knowledge Layer | ⏳ Planned |
| M05 – MCP Services | ⏳ Planned |
| M06 – Monitoring & Operations | ⏳ Planned |
| M07 – Backup & Disaster Recovery | ⏳ Planned |

---

## High-Level Architecture

```text
Windows Workstation
        │
SSH + Tailscale
        │
──────────────────────────────
Mac mini M4 Pro
──────────────────────────────
        │
      launchd
        │
 ┌──────┴────────┐
 │               │
Ollama      OpenClaw
 │               │
 └──────┬────────┘
        │
  Local AI Models
        │
──────────────────────────────
Docker Compose
──────────────────────────────
Qdrant
Grafana
Prometheus
Uptime Kuma
```

---

## Technology Stack

### Native Services

- Ollama
- OpenClaw (planned)

### Containerized Services

- Docker Compose
- Qdrant (planned)
- Grafana (planned)
- Prometheus (planned)
- Uptime Kuma (planned)

### Networking

- Tailscale
- SSH (Ed25519 Key Authentication)

### Development

- Git
- GitHub
- Homebrew
- Xcode Command Line Tools
- Docker Desktop

---

## Initial AI Models

| Model | Purpose |
| -------- | --------- |
| Qwen3 14B | Primary reasoning model |
| Gemma 3 12B | Coding and structured tasks |
| nomic-embed-text | Embeddings and semantic search |

---

## Repository Structure

```text
.
├── bootstrap/
├── docker/
├── infrastructure/
├── scripts/
├── services/
├── docs/
│   ├── architecture/
│   ├── decisions/
│   ├── milestones/
│   ├── runbooks/
│   └── templates/
└── inventory/
```

---

## Documentation

### Architecture

Describes how the platform is designed.

- System Overview
- Runtime Architecture
- Service Management
- Network Architecture
- Directory Layout

---

### Architecture Decision Records (ADRs)

Documents significant architectural decisions.

Current ADRs include:

- ADR-0001 – Separate AI Account
- ADR-0002 – Tailscale Only Remote Access
- ADR-0003 – Ollama Model Storage
- ADR-0004 – launchd vs Docker Compose
- ADR-0005 – Official Ollama Installation
- ADR-0006 – Architecture as Code

---

### Milestones

Milestones document the implementation roadmap.

- M01 – Foundation
- M02 – AI Runtime Layer
- M03 – OpenClaw Platform
- M04 – Knowledge Layer
- M05 – MCP Services

---

### Runbooks

Runbooks provide repeatable operational procedures.

Examples include:

- Install Ollama
- Configure Ollama
- Verify Ollama
- Update Ollama
- Recover Ollama

---

## Design Principles

The platform follows several guiding principles.

### Local First

Run AI workloads locally whenever practical.

---

### Least Privilege

Services execute with the minimum required permissions.

---

### Infrastructure as Code

Infrastructure should be reproducible from version-controlled configuration.

---

### Documentation as Code

Documentation evolves alongside the platform and is treated as a first-class component.

---

### Modular Architecture

Services should be loosely coupled and independently maintainable.

---

### Observability

Every service should provide:

- Logging
- Health checks
- Verification procedures
- Operational runbooks

---

## Long-Term Roadmap

Future milestones include:

- OpenClaw integration
- Semantic search
- Obsidian RAG
- MCP server ecosystem
- AI-assisted software development
- Monitoring dashboards
- Automated backups
- Disaster recovery
- Multi-model routing
- Performance benchmarking

---

## Repository Philosophy

This repository is the single source of truth for the Personal AI Server.

Configuration, documentation, architecture, operational procedures, and implementation history are maintained together to ensure the platform remains understandable, reproducible, and maintainable over its entire lifecycle.
