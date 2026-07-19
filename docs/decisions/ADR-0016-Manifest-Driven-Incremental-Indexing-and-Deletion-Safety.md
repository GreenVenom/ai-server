---
title: ADR-0016 — Manifest-Driven Incremental Indexing and Deletion Safety
document: ADR
status: Accepted
created: 2026-07-18
updated: 2026-07-18
platform_version: v0.5.0
owner: GreenVenom
decision_id: ADR-0016
milestone: M05
supersedes: null
superseded_by: null
---

# ADR-0016 — Manifest-Driven Incremental Indexing and Deletion Safety

**Status:** Accepted  
**Date:** 2026-07-19

## Context

Re-embedding every note on every synchronization is inefficient, while deleting stale Qdrant points without a trusted reconciliation record is unsafe. File modifications may represent source changes, metadata-only changes, exclusions, deletions, or renames.

## Decision

Maintain an atomic, mode-`0600` manifest for each vault. Compare discovered documents and their source, metadata, and chunk hashes with the manifest to classify changes. Re-embed and upsert only affected chunks. Reconcile stale points against deterministic chunk IDs.

Reject reconciliations that would delete more than 10 percent of indexed documents or points unless explicitly approved.

## Consequences

### Positive

- Unchanged runs perform no embedding or Qdrant writes.
- Index state is deterministic and auditable.
- Metadata-only and source changes can be handled differently.
- Stale points are removed safely.
- Large accidental source loss is blocked.

### Negative

- The manifest becomes required operational state for incremental runs.
- Changes to identity or chunking policy require a controlled migration or full rebuild.
- Large intentional reorganizations require explicit deletion approval.

## Related documentation

- [Obsidian data contract](../engineering/Obsidian-Data-Contract.md)
- [Obsidian operations runbook](../operations/runbooks/Obsidian-Operations.md)
