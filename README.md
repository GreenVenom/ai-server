---
title: README
document: README
version: 2.0
status: Complete
created: 2026-07-12
updated: 2026-07-13
author: GreenVenom
-------------

# Personal AI Platform

> A production-quality, local-first AI platform engineered for privacy, reproducibility, operational excellence, and long-term maintainability.

---

## Vision

The Personal AI Platform provides a secure, self-hosted environment for AI-assisted development, knowledge management, and automation while minimizing reliance on external cloud AI services.

The platform is designed to evolve incrementally through documented milestones, architecture decisions, and operational best practices.

---

## Project Goals

* Local-first AI inference
* Minimal cloud AI usage
* Secure remote administration
* Production-quality operations
* Knowledge management
* AI-assisted software development
* Infrastructure as Code
* Reproducible platform builds
* Comprehensive engineering documentation

---

## Platform Hardware

| Component              | Specification              |
| ---------------------- | -------------------------- |
| Platform               | Apple Mac mini (M4 Pro)    |
| Memory                 | 24 GB Unified Memory       |
| Storage                | 512 GB SSD                 |
| Primary Administration | Windows 11 (SSH + VS Code) |
| Remote Access          | Tailscale                  |

---

## Core Platform Components

| Component      | Purpose                               |
| -------------- | ------------------------------------- |
| Ollama         | Local AI inference runtime            |
| OpenClaw       | AI orchestration platform             |
| Docker Desktop | Container runtime                     |
| Qdrant         | Vector database                       |
| Obsidian       | Knowledge management                  |
| MCP Servers    | External tool integrations            |
| GitHub         | Repository backup and version control |

---

## Repository Philosophy

This repository is the authoritative source of truth for the Personal AI Platform.

It contains:

* Architecture documentation
* Engineering principles
* Milestones
* Architecture Decision Records (ADRs)
* Runbooks
* Platform configuration
* Operational scripts
* Templates
* Release documentation

The platform should be reproducible from this repository together with official vendor installers.

---

## Repository Layout

```text
.
├── README.md
├── ROADMAP.md
├── VERSION.md
│
├── docs/
│   ├── architecture/
│   ├── decisions/
│   ├── glossary/
│   ├── milestones/
│   ├── platform-config/
│   ├── releases/
│   ├── runbooks/
│   └── templates/
│
├── scripts/
│
└── server/
    ├── config/
    ├── data/
    ├── docker/
    ├── logs/
    ├── backups/
    └── services/
```

---

## Documentation Reading Order

The documentation is organized from strategic guidance to operational implementation.

### 1. Platform Foundation

Start here to understand the project.

* M00 – Platform Charter
* Engineering Principles
* Glossary

---

### 2. Platform Status

Understand the current state of the platform.

* VERSION.md
* ROADMAP.md

---

### 3. Architecture

Learn how the platform is designed.

* System Overview
* Runtime Architecture
* Service Management
* Network Architecture
* Directory Layout

---

### 4. Engineering Decisions

Review significant architectural decisions.

* Architecture Decision Records (ADRs)

---

### 5. Milestones

Understand how the platform evolved.

* M01 – Foundation
* M02 – Production Ollama Runtime
* M03–M12 (planned)

---

### 6. Platform Configuration

Reference documentation for installed software.

* Ollama
* Docker Desktop
* Tailscale
* (Additional platform components)

---

### 7. Runbooks

Operational procedures.

Examples include:

* Health verification
* Platform updates
* Backup and restore
* Disaster recovery

---

### 8. Release Notes

Historical platform changes.

---

## Engineering Principles

The platform follows several guiding principles.

* Documentation First
* Git as the Source of Truth
* Infrastructure as Code
* Vendor-Supported Solutions
* Automation by Default
* Operational Readiness
* Security by Design
* Incremental Delivery

See **Engineering Principles** for the complete philosophy.

---

## Development Workflow

Every significant change follows the same lifecycle.

```text
Idea
    ↓
Architecture Discussion
    ↓
Architecture Decision Record (ADR)
    ↓
Milestone Planning
    ↓
Implementation
    ↓
Validation
    ↓
Documentation
    ↓
Git Commit
    ↓
Release Tag
```

---

## Versioning

The platform follows Semantic Versioning.

* Major versions represent production releases.
* Minor versions correspond to completed milestones.
* Patch versions contain maintenance improvements and documentation updates.

See `VERSION.md` for the current platform version.

---

## Current Roadmap

| Version | Milestone                     | Status          |
| ------- | ----------------------------- | --------------- |
| v0.1.0  | Foundation                    | ✅ Complete     |
| v0.2.0  | Production Ollama Runtime     | 🚧 In Progress  |
| v0.3.0  | OpenClaw Platform             | ⏳ Planned      |
| v0.4.0  | Docker Platform               | ⏳ Planned      |
| v0.5.0  | Qdrant                        | ⏳ Planned      |
| v0.6.0  | Obsidian Integration          | ⏳ Planned      |
| v0.7.0  | Platform Operations Framework | ⏳ Planned      |
| v0.8.0  | MCP Ecosystem                 | ⏳ Planned      |
| v0.9.0  | Observability & Monitoring    | ⏳ Planned      |
| v0.9.5  | Production Hardening          | ⏳ Planned      |
| v0.9.8  | Backup & Disaster Recovery    | ⏳ Planned      |
| v1.0.0  | Production Release            | ⏳ Planned      |

---

## Success Criteria

Version **1.0** is achieved when:

* All planned milestones are complete.
* Documentation is current.
* Health checks pass.
* Operational procedures are documented.
* Disaster recovery has been validated.
* The platform can be rebuilt from bare hardware using this repository and official vendor installers.

---

## License

This repository is maintained as the engineering documentation and operational handbook for the Personal AI Platform.

Its primary purpose is to ensure the platform remains secure, reproducible, maintainable, and well documented throughout its lifecycle.
