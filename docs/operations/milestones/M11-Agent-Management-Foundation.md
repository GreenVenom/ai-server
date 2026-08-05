---
title: M11 Agent Management Foundation
document: Milestone
status: Planned
created: 2026-08-04
updated: 2026-08-04
platform_version: v0.8.0
owner: GreenVenom
---

# M11 Agent Management Foundation

## Objective

Establish governed lifecycle management for AI agents.

## Scope

Included:

- Versioned agent definitions with schemas and validation.
- Per-agent model, retrieval, tool, permission, and runtime assignments.
- Enable, disable, inspect, and test controls.
- Audit records, status, and configuration backup/restore coverage.

Excluded:

- Guided agent authoring, which is M13.
- Broad write-capable automation, which is M14.

## Success Criteria

- Invalid or incomplete definitions cannot be activated.
- Every active agent has explicit, inspectable assignments and audit history.
- Lifecycle controls and restore coverage are tested and documented.

## Exit Criteria

M11 is complete when governed agent definitions, lifecycle controls, auditability, recovery controls, tests, and documentation are verified.

## Related Documentation

- [Roadmap](../../../ROADMAP.md)
- [M12 Curated MCP Catalog and Governance](M12-Curated-MCP-Catalog-and-Governance.md)
