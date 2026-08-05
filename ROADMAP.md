---
title: 🗺️ Roadmap
document: Reference
status: Active
created: 2026-07-14
updated: 2026-08-04
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

## M09 — Model Lifecycle, Selection, and Routing 🔜

Status: Planned

Establish controlled acquisition, evaluation, activation, rollback, and routing for approved local models. The milestone includes a pinned model catalog and profiles, 24 GB server capacity safeguards, model inventory and selection controls, and primary, fallback, embedding, and agent-specific routing policy. Hermes is optional and must have a defined role; it is not a platform-wide replacement.

## M10 — Secure Primary-Workstation Web UI 🔜

Status: Planned

Provide an authenticated, Tailscale-only control plane for chat, retrieval, health, model inventory, and model selection. It will use approved backend APIs and will not expose Ollama, Qdrant, OpenClaw, or backup endpoints directly to the browser.

## M11 — Agent Management Foundation 🔜

Status: Planned

Introduce governed, versioned agent definitions with schemas, validation, lifecycle controls, per-agent runtime assignments, audit records, status, and backup/restore coverage.

## M12 — Curated MCP Catalog and Governance 🔜

Status: Planned

Extend the M06 baseline through a reviewed first-party or explicitly approved MCP catalog, per-agent allowlists, tool-level least-privilege boundaries, read-only-by-default controls, validation, security tests, and audit visibility. Arbitrary public or community MCP installation is out of scope.

## M13 — Guided AI Agent Creation 🔜

Status: Planned

Provide guided UI and CLI workflows that create agents from approved templates and validated model, retrieval, and MCP selections. Definitions must support preview/testing, ownership, version history, and rollback before activation.

## M14 — Controlled Automated File-Update Workflows 🔜

Status: Planned

Allow agents to propose and apply file changes only in explicitly approved repository or workspace scopes. The workflow requires deny-by-default writes, dry runs, diff previews, approval gates, Git-backed commits and rollback, queue visibility, audit logging, backup coverage, and security acceptance tests.

## M15 — v2.0.0 Hardening and Release 🔜

Status: Planned

Validate the complete platform and publish v2.0.0. Completion requires end-to-end acceptance testing, a security review, current architecture and operational documentation, final release verification, a version bump, annotated tag, and release notes.

## Script Evolution

| Area | Roadmap change |
| --- | --- |
| `status.sh`, `health.sh`, `verify.sh` | Report UI, model registry, agent runtime, MCP policy state, automation queue, and backup freshness. |
| `doctor.sh` | Validate capacity, authentication, configuration schemas, MCP allowlists, Git availability, and approved writable boundaries. |
| `install.sh`, `update.sh` | Manage pinned dependencies, configuration migrations, and rollback-safe updates. |
| `backup.sh`, `restore.sh` | Include model, agent, MCP, UI, and automation configuration/manifests; continue excluding secrets, logs, virtual environments, images, and server-side Obsidian mirrors. |
| New commands | Add model, agent, MCP catalog, automation, and UI deployment/verification commands using the shared validation, result, error, and logging libraries. |

## Release Policy

M01–M08 establish the production foundation. M09–M14 introduce v2 capabilities incrementally, with feature-specific releases as appropriate. `v2.0.0` is reserved for successful M15 completion, when the secure workflow is proven end-to-end: model management → UI → agents → governed MCP → approved file automation.

## 🔗 Related documentation

- [Documentation map](docs/README.md)
