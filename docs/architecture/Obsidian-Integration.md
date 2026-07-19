---
title: Obsidian Integration Architecture
document: Architecture
status: Active
created: 2026-07-18
updated: 2026-07-18
platform_version: v0.5.0
owner: GreenVenom
---

# Obsidian Integration Architecture

## Purpose

This document describes the architecture of the production Obsidian ingestion and retrieval subsystem.

## Trust boundaries

The authoritative Obsidian vault remains on the primary Windows workstation. The Mac mini receives only a controlled copy of the repository and produces a Markdown-only mirror for ingestion.

```text
Windows workstation                         Mac mini
┌──────────────────────────┐               ┌──────────────────────────┐
│ Authoritative vault      │               │ Read-only Git checkout   │
│ User-managed content     │──Git/SSH─────▶│ repository-scoped key    │
└──────────────────────────┘               └────────────┬─────────────┘
                                                       │ Markdown only
                                                       ▼
                                          ┌──────────────────────────┐
                                          │ Non-authoritative mirror │
                                          └────────────┬─────────────┘
                                                       ▼
                                          ┌──────────────────────────┐
                                          │ Ingestion service        │
                                          └────────────┬─────────────┘
                                                       ▼
                                          ┌──────────────────────────┐
                                          │ Ollama embeddings        │
                                          └────────────┬─────────────┘
                                                       ▼
                                          ┌──────────────────────────┐
                                          │ Qdrant                   │
                                          └────────────┬─────────────┘
                                                       ▼
                                          ┌──────────────────────────┐
                                          │ OpenClaw retrieval tool  │
                                          └──────────────────────────┘
```

## Data classes

| Data class | Authority | Recoverability |
|---|---|---|
| Obsidian notes | Windows vault | Authoritative private Git repository |
| Server Git checkout | Derived working copy | Re-clone from Git |
| Markdown mirror | Derived working copy | Recreate with sync script |
| Manifest | Derived operational state | Rebuild with full index |
| Embeddings and Qdrant points | Derived index | Rebuild or restore snapshot |
| Job state and logs | Operational evidence | Recreated by scheduled job |

## Identity model

Document and chunk identifiers are deterministic. Stable identities make idempotent indexing, reconciliation, rename handling, and recovery testable.

- Document IDs are derived from vault identity and normalized source path.
- Chunk IDs are derived from the document identity and chunk identity inputs.
- Source and metadata hashes distinguish content changes from metadata-only changes.
- Every Qdrant payload includes a schema version.

## Collection contract

```text
collection        obsidian_chunks_v1
vector name       text-dense
size              768
metric            Cosine
embedding model   nomic-embed-text:latest
payload schema    v2
```

The collection may contain multiple vaults, but every production query must include a `vault_id` filter.

## Retrieval boundary

The OpenClaw plugin invokes a dedicated local wrapper instead of reading the mirror or querying arbitrary Qdrant collections directly.

Boundary controls:

- fixed production collection;
- fixed default vault ID;
- maximum query length of 500 characters;
- maximum result count of 8;
- default score threshold of 0.35;
- structured JSON output;
- source path and heading included in results;
- no note modification capability.

## Synchronization and indexing

The scheduled job performs these phases:

1. Acquire an outer job lock.
2. Fetch and fast-forward the Git working copy.
3. Synchronize Markdown only into the mirror.
4. Apply restrictive permissions.
5. Run incremental classification.
6. Re-embed only added or changed chunks.
7. Remove stale points only when deletion policy allows it.
8. Write the manifest atomically.
9. Write durable job state.
10. Release locks and retain timestamped logs.

## Failure behavior

- Concurrent runs are rejected.
- Git divergence causes the sync to fail rather than create a merge.
- Missing repository, vault marker, environment, mirror, or manifest causes a nonzero exit.
- Excessive deletions require explicit approval.
- Scheduled job failures are recorded in the durable state JSON.
- Health checks compare mirror documents, manifest entries, and Qdrant point IDs.

## Related documentation

- [M05 milestone record](../operations/milestones/M05-Obsidian-Integration.md)
- [Obsidian data contract](../engineering/Obsidian-Data-Contract.md)
- [Obsidian operations runbook](../operations/runbooks/Obsidian-Operations.md)
