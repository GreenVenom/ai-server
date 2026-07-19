---
title: Roadmap
document: Reference
status: Active
created: 2026-07-17
updated: 2026-07-18
platform_version: v0.5.0
owner: GreenVenom
---

# Roadmap

## M01 — Foundation ✅

Status: Complete

Delivered:

- initial repository structure
- engineering principles
- documentation architecture
- system architecture documentation
- versioning and release structure
- core host setup
- secure administration foundation

## M02 — Production Ollama Runtime ✅

Status: Complete

Delivered:

- production Ollama runtime
- persistent local model storage
- reboot persistence
- local-only Ollama API binding
- validated primary generation models
- validated embedding model
- operational health and verification scripts
- provider-neutral Benchmark Framework
- structured Error Repository
- structured Result Repository
- model and prompt APIs
- profile-driven benchmark execution
- generation and embedding execution
- Markdown, JSON, CSV, and text reporting
- successful Qwen and Gemma benchmark paths
- benchmark validation test suite

Primary models:

```text
qwen3:14b
gemma4:12b
nomic-embed-text:latest
```

Architecture decisions:

```text
ADR-0007
ADR-0008
ADR-0009
```

## M03 — OpenClaw Platform ✅

Status: Complete

Delivered:

- OpenClaw 2026.7.1 with a LaunchAgent-managed, loopback-only Gateway
- local Ollama routing with Gemma 4 12B primary and Qwen3 14B fallback models
- token authentication and a hardened local-only control plane
- Docker sandboxing with a dedicated read-write productive workspace
- OpenClaw-aware status, doctor, health, and verification scripts
- reboot-persistence validation and Docker Desktop auto-start at user login
- zero critical findings in the deep security audit

## M04 — Qdrant ✅

Status: Complete

Delivered:

- Qdrant 1.18.2 deployed through Docker Compose with loopback-only REST and gRPC endpoints.
- Durable Docker named-volume storage and validated `restart: always` lifecycle recovery.
- Validated `nomic-embed-text:latest` embeddings with 768 dimensions and the `text-dense` named vector.
- Deterministic collection, point, payload, hashing, and timestamp conventions.
- Semantic retrieval, payload filtering, and deterministic deletion validation.
- Portable snapshots, SHA-256 manifests, clean restore validation, and retention tooling.
- Qdrant integration into platform status, health, and verification scripts.

## M05 — Obsidian Integration ✅

Status: Complete

Delivered:

- controlled read-only vault mirror
- Markdown discovery, parsing, chunking, and local embeddings
- Qdrant production collection and incremental reconciliation
- OpenClaw `obsidian_search` retrieval tool
- scheduled synchronization, health checks, and operational backup

## M06 — MCP Servers ⏳

Status: Next

Objectives:

- expose approved platform capabilities through narrow MCP interfaces
- reuse the M05 Obsidian retrieval boundary
- preserve local-first and least-privilege controls

## M07 — Monitoring ⏳

Objectives:

- runtime visibility
- service health
- benchmark trend tracking
- resource monitoring
- alerting strategy

## M08 — Backup & Disaster Recovery ⏳

Objectives:

- backup runtime configuration
- backup persistent data
- validate restore procedures
- document disaster recovery

## Future Work

Potential later milestones include:

- richer benchmark statistics
- multi-provider benchmark comparison
- automated baseline regression detection
- expanded local model routing
- additional retrieval and agent workflows

## Related documentation

- [Documentation map](docs/README.md)
