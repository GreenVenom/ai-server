---
title: M05 — Obsidian Integration
document: Milestone
status: Complete
created: 2026-07-18
updated: 2026-07-18
platform_version: v0.5.0
owner: GreenVenom
---

# M05 — Obsidian Integration

**Completed:** July 18, 2026  
**Predecessor:** M04 — Qdrant Vector Database  
**Release:** v0.5.0

## Objective

Deliver a secure, local-first Obsidian ingestion and retrieval capability for the Personal AI Platform.

The milestone establishes a controlled, read-only server mirror of an authoritative Obsidian vault, transforms approved Markdown into stable retrieval chunks, embeds those chunks locally with Ollama, stores them in Qdrant, and exposes a constrained retrieval tool to OpenClaw.

## Production architecture

```text
Authoritative Obsidian vault on Windows
    ↓ private Git repository and read-only deploy key
Server-side Git working copy
    ↓ Markdown-only synchronization
Read-only vault mirror
    ↓ discovery, parsing, filtering, chunking and hashing
Ollama nomic-embed-text:latest
    ↓ 768-dimensional text-dense vectors
Qdrant obsidian_chunks_v1
    ↓ constrained retrieval boundary
OpenClaw obsidian_search tool
    ↓ grounded local-model response
```

## Completed scope

- Registered the `personal-knowledge` vault.
- Preserved the Windows Obsidian vault as the authoritative source.
- Configured a dedicated read-only GitHub deploy key and SSH alias.
- Created a Markdown-only server mirror.
- Excluded `.git`, `.obsidian`, `.smart-env`, Smart Connections data, and non-Markdown files.
- Implemented Markdown discovery and exclusion handling.
- Implemented YAML frontmatter parsing.
- Captured titles, headings, aliases, tags, links, hashes, and source paths.
- Implemented deterministic document and chunk identities.
- Implemented the `heading-aware-v1` chunking profile.
- Embedded content with `nomic-embed-text:latest`.
- Created and validated `obsidian_chunks_v1`.
- Implemented full and incremental indexing.
- Implemented manifest-based change detection and reconciliation.
- Added deletion-threshold protection.
- Validated additions, changes, metadata-only changes, exclusions, deletions, renames, chunk reductions, and idempotent runs.
- Implemented semantic search with vault filtering.
- Implemented a constrained JSON retrieval boundary.
- Added the OpenClaw `obsidian-retrieval` plugin and `obsidian_search` tool.
- Onboarded the production vault.
- Added hourly and login-triggered synchronization through a user LaunchAgent.
- Added durable job state, lock handling, logs, log retention, health checks, status reporting, and operational backups.

## Production configuration

| Setting | Value |
|---|---|
| Vault ID | `personal-knowledge` |
| Authoritative source | Private Git repository from the Windows workstation |
| Server Git working copy | `~/server/data/obsidian/repos/personal-knowledge-source` |
| Read-only mirror | `~/server/data/obsidian/vaults/personal-knowledge` |
| Manifest | `~/server/data/obsidian/manifests/personal-knowledge.json` |
| Qdrant collection | `obsidian_chunks_v1` |
| Named vector | `text-dense` |
| Dimensions | `768` |
| Distance | `Cosine` |
| Embedding model | `nomic-embed-text:latest` |
| Chunking profile | `heading-aware-v1` |
| Retrieval tool | `obsidian_search` |
| Scheduled job | `ai.openclaw.obsidian-sync-index` |
| Job interval | 3600 seconds and RunAtLoad |
| Deletion approval threshold | 10 percent |

## Production acceptance results

| Acceptance test | Result |
|---|---:|
| Source discovery | 7 of 7 notes eligible |
| Parse issues | 0 |
| Production documents indexed | 7 |
| Production chunks indexed | 176 |
| Manifest permissions | `0600` |
| Manifest/Qdrant reconciliation | Pass |
| Collection status | Green |
| Collection total points | 184, including 8 fixture points |
| Production retrieval — Honeygain | Pass |
| Production retrieval — D&D books | Pass |
| Production retrieval — TO-DOs | Pass |
| OpenClaw TUI retrieval | Pass |
| Unchanged incremental run | Pass |
| Concurrent-run protection | Pass |
| Scheduled LaunchAgent run | Pass |
| Obsidian health checks | 10 of 10 pass |
| Platform health after integration | 55 of 55 pass |
| Operational backup | Pass |
| Snapshot checksum validation | Pass |

## Delivered components

### Ingestion service

```text
services/obsidian/src/obsidian_ingest/
├── __init__.py
├── chunking.py
├── discovery.py
├── embeddings.py
├── identity.py
├── incremental.py
├── indexer.py
├── manifest.py
├── parser.py
├── qdrant.py
├── retrieval_boundary.py
└── search.py
```

### OpenClaw plugin

```text
services/openclaw-obsidian-plugin/
├── src/
├── openclaw.plugin.json
├── package.json
├── package-lock.json
└── tsconfig.json
```

### Operations

```text
scripts/sync-obsidian-vault.sh
scripts/obsidian-sync-index.sh
scripts/obsidian-sync-index-runner.sh
scripts/obsidian-search.sh
scripts/check-obsidian.sh
scripts/cleanup-obsidian-logs.sh
scripts/backup-obsidian.sh
services/launchagents/ai.openclaw.obsidian-sync-index.plist
```

## Security outcomes

- OpenClaw has no direct access to the authoritative workstation vault.
- The server mirror is non-authoritative and read-only by policy.
- The Git deploy key is repository-specific and read-only.
- The mirror contains Markdown only.
- Retrieval is constrained by vault ID, query length, result count, and threshold.
- The OpenClaw tool is optional and explicitly allowlisted.
- Configuration, manifests, state files, and backups use restrictive permissions.
- Qdrant remains bound to loopback.
- Destructive reconciliation is protected by a deletion threshold.

## Deferred work

- Strip inline `data:image/...` payloads during parsing.
- Add optional sparse or hybrid search.
- Add reranking only if retrieval evaluations justify it.
- Add multi-vault policy if a second production vault is onboarded.
- General MCP exposure remains part of M06.

## Milestone decision

M05 is complete. The platform now provides dependable, automated, and operationally observable retrieval over an approved Obsidian knowledge base.

## Related documentation

- [v0.5.0 release notes](../../releases/v0.5.0.md)
- [Obsidian integration architecture](../../architecture/Obsidian-Integration.md)
- [Obsidian operations runbook](../runbooks/Obsidian-Operations.md)
