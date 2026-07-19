---
title: Architecture Index
document: Architecture
status: Active
created: 2026-07-17
updated: 2026-07-18
platform_version: v0.3.0
owner: GreenVenom
---

# Architecture Index

This directory contains the high-level architectural documentation for the Personal AI Platform.

## Documents

| Document | Purpose |
| --- | --- |
| System Overview | Overall platform architecture |
| Runtime Architecture | AI runtime and inference layer |
| Service Management | Service lifecycle and orchestration |
| Network Architecture | Connectivity and security |
| Directory Layout | Filesystem organization |
| Documentation Architecture | Documentation system and responsibilities |
| Benchmark Framework | Layered, provider-neutral benchmark design |
| Benchmark Profiles | Reusable benchmark execution defaults |
| Error Framework | Structured error handling for benchmarks |
| Repository Pattern | In-memory repository conventions for Bash |
| OpenClaw Architecture | Orchestration and agent-layer design |
| Obsidian Integration | Controlled ingestion and retrieval architecture |

## ADRs by milestone

| Milestone | ADRs |
| --- | --- |
| M01 — Foundation | ADR-0001 through ADR-0006 |
| M02 — Production Ollama Runtime | ADR-0007 through ADR-0009 |
| M04 — Qdrant | ADR-0010 through ADR-0013 |
| M05 — Obsidian Integration | ADR-0014 through ADR-0016 |

### Design Principles

- Local-first AI
- Security by default
- Infrastructure as Code
- Documentation as Code
- Least privilege
- Reproducible deployments
- Modular services
- Observable systems

### Related Documents

- ADRs
- Milestones
- Runbooks

## Related documentation

- [Documentation map](../README.md)
