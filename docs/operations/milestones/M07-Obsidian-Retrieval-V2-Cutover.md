---
title: M07 - Obsidian Retrieval V2 Cutover
document: Milestone
status: Complete
created: 2026-07-27
updated: 2026-07-27
platform_version: v0.7.0
owner: GreenVenom
---

# M07 - Obsidian Retrieval V2 Cutover

## Summary

M07 moved the production `personal-knowledge` Obsidian retrieval workload from the V1 index to an independently rebuilt V2 index, while preserving V1 as a controlled rollback target.

## Objective

Make the validated V2 retrieval index the production source for indexing and query paths without losing a known-good V1 recovery path.

## Scope

M07 includes the V2 collection and manifest cutover, production configuration changes, reconciliation validation, and documented rollback retention. Broader backup and disaster-recovery validation remains in M08.

## Deliverables

- Live `obsidian_chunks_v2` collection and `data/obsidian/manifests-v2` manifest root.
- V2 configuration for the indexer, scheduled LaunchAgent, MCP adapter, and OpenClaw Obsidian plugin.
- Exact manifest-to-Qdrant chunk-ID reconciliation.
- A 30-day minimum V1 retention and rollback procedure.
- ADR-0022 and v0.7.0 release notes.

## Validation

The accepted cutover confirmed 39 V2 manifest documents, 265 Qdrant chunks, a successful incremental scheduler run with zero upserts and deletions, a loaded LaunchAgent with exit code 0, healthy MCP services, and exact agreement between V2 manifest chunk IDs and Qdrant point IDs.

## Exit criteria

Complete. V2 is the live retrieval configuration, the production components target V2, and V1 is retained unchanged for rollback under the ADR-0022 contract.

## Related documentation

- [ADR-0022](../../decisions/ADR-0022-obsidian-index-v2-cutover-and-v1-rollback-retention.md)
- [v0.7.0 release notes](../../releases/v0.7.0.md)
- [Roadmap](../../../ROADMAP.md)