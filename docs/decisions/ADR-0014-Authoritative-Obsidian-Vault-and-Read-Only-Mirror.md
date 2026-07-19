---
title: ADR-0014 — Authoritative Obsidian Vault and Read-Only Server Mirror
document: ADR
status: Accepted
created: 2026-07-18
updated: 2026-07-18
platform_version: v0.5.0
owner: GreenVenom
decision_id: ADR-0014
milestone: M05
supersedes: null
superseded_by: null
---

# ADR-0014 — Authoritative Obsidian Vault and Read-Only Server Mirror

**Status:** Accepted  
**Date:** 2026-07-19

## Context

The Personal AI Platform needs access to Obsidian content, but the authoritative vault resides on the primary Windows workstation and contains user-managed knowledge. Giving the server or OpenClaw direct access to the live workstation vault would enlarge the trust boundary and create unnecessary write risk.

## Decision

The Windows Obsidian vault remains authoritative. A repository-specific, read-only deploy key allows the Mac mini to maintain a Git working copy. A synchronization script copies only Markdown files into a non-authoritative server mirror. Ingestion and retrieval operate exclusively on this mirror.

## Consequences

### Positive

- OpenClaw cannot modify the authoritative vault.
- The ingestion boundary excludes Obsidian settings, Git metadata, plugin data, and unrelated files.
- The mirror and derived index can be destroyed and recreated safely.
- Source history and recovery remain managed by private Git.

### Negative

- Changes are not visible until committed and synchronized.
- Git and mirror state require operational monitoring.
- Bidirectional note editing is intentionally unavailable.

## Alternatives rejected

- Directly mount or share the live Windows vault.
- Give OpenClaw unrestricted filesystem access.
- Treat Qdrant as the authoritative knowledge store.
- Implement bidirectional synchronization during M05.

## Related documentation

- [Obsidian integration architecture](../architecture/Obsidian-Integration.md)
- [M05 milestone record](../operations/milestones/M05-Obsidian-Integration.md)
