---
title: 🗺️ Roadmap
document: Reference
status: Active
created: 2026-07-14
updated: 2026-07-28
platform_version: v0.8.0
owner: GreenVenom
---

# 🗺️ Roadmap

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

Architecture decisions: ADR-0001 through ADR-0006.

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

Architecture decisions: ADR-0010 through ADR-0013.

## M05 — Obsidian Integration ✅

Status: Complete

Delivered:

- controlled read-only vault mirror
- Markdown discovery, parsing, chunking, and local embeddings
- Qdrant production collection and incremental reconciliation
- OpenClaw `obsidian_search` retrieval tool
- scheduled synchronization, health checks, and operational backup

Architecture decisions: ADR-0014 through ADR-0016.

## M06 — MCP Services ✅

Status: Complete

Delivered:

- two local stdio MCP servers for Obsidian retrieval and platform inspection
- eight exact read-only tools with strict schemas and sanitized errors
- explicit OpenClaw filters and sandbox authorization
- restricted subprocess execution, output limits, and timeouts
- unit, integration, security, policy, and ten-scenario agent acceptance tests
- status, health, and verification integration requiring two servers, eight tools, and zero diagnostics

Architecture decisions: ADR-0017 through ADR-0021.

## M07 — Obsidian Retrieval V2 Cutover ✅

Status: Complete

Delivered:

- production cutover to the independently rebuilt `obsidian_chunks_v2` collection
- a dedicated V2 manifest root at `data/obsidian/manifests-v2`
- V2 configuration for the indexer scheduler, MCP adapter, and OpenClaw plugin
- manifest-to-Qdrant chunk-ID reconciliation that excludes intentional non-indexable mirror content
- a documented V1 rollback and 30-day retention contract

Architecture decision: [ADR-0022](docs/decisions/ADR-0022-obsidian-index-v2-cutover-and-v1-rollback-retention.md).

## M08 — Backup & Disaster Recovery ✅

Status: Complete

Delivered:

- encrypted, off-host backups of the active V2 Qdrant index and allow-listed non-secret runtime configuration
- automated daily backup execution with integrity manifests, upload verification, retention controls, and capacity fail-closed behavior
- a non-production Qdrant restore drill with checksum, vector-contract, point-count, and manifest-reconciliation validation
- a recovery runbook, off-host backup ADR, and v0.8.0 release record

Architecture decision: [ADR-0023](docs/decisions/ADR-0023-Encrypted-Google-Drive-Off-Host-Backups.md).

## M09 — Future Plans 🔜

Status: Planned

M09 is reserved for future platform work. Its scope will be defined in a milestone record before implementation begins.

Potential future plans include:

- richer benchmark statistics
- multi-provider benchmark comparison
- automated baseline regression detection
- expanded local model routing
- additional retrieval and agent workflows

## 🔗 Related documentation

- [Documentation map](docs/README.md)
