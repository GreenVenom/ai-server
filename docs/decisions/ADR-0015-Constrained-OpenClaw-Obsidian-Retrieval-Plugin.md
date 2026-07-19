---
title: ADR-0015 — Constrained OpenClaw Obsidian Retrieval Plugin
document: ADR
status: Accepted
created: 2026-07-18
updated: 2026-07-18
platform_version: v0.5.0
owner: GreenVenom
decision_id: ADR-0015
milestone: M05
supersedes: null
superseded_by: null
---

# ADR-0015 — Constrained OpenClaw Obsidian Retrieval Plugin

**Status:** Accepted  
**Date:** 2026-07-19

## Context

OpenClaw requires semantic retrieval from Obsidian, but direct access to the mirror, ingestion internals, arbitrary Qdrant collections, or unrestricted shell commands would expose a broader capability than necessary.

## Decision

Expose retrieval through a dedicated optional OpenClaw plugin named `obsidian-retrieval`. The plugin registers one tool, `obsidian_search`, and invokes a constrained local retrieval boundary.

The boundary fixes or limits:

- production collection;
- default vault ID;
- query length;
- result count;
- score threshold;
- structured output fields;
- read-only behavior.

The tool is explicitly allowlisted in OpenClaw configuration.

## Consequences

### Positive

- The agent receives the minimum required capability.
- Retrieval behavior can be tested independently of OpenClaw.
- Source paths and headings support grounded responses.
- Future MCP tooling can consume the same boundary without duplicating ingestion logic.

### Negative

- The plugin and wrapper must be maintained alongside OpenClaw updates.
- Advanced query features require deliberate boundary changes.
- The current implementation is specific to semantic retrieval rather than general vault operations.

## Alternatives rejected

- Direct filesystem tools.
- General shell execution.
- Direct Qdrant access from prompts or agents.
- Embedding Obsidian-specific logic in a future generic MCP server.

## Related documentation

- [Obsidian integration architecture](../architecture/Obsidian-Integration.md)
- [M05 milestone record](../operations/milestones/M05-Obsidian-Integration.md)
