---
title: M12 Curated MCP Catalog and Governance
document: Milestone
status: Planned
created: 2026-08-04
updated: 2026-08-04
platform_version: v0.8.0
owner: GreenVenom
---

# M12 Curated MCP Catalog and Governance

## Objective

Extend the M06 MCP baseline through explicit, least-privilege catalog and per-agent controls.

## Scope

Included:

- A reviewed catalog of first-party or explicitly approved MCP servers.
- Per-agent allowlists and tool-level permission boundaries.
- Read-only-by-default policy, sensitive-operation approval requirements, and enable/disable controls.
- Configuration validation, fixtures, security tests, and audit visibility.

Excluded:

- Arbitrary public or community MCP server installation.

## Success Criteria

- Agents can invoke only approved servers and explicitly allowlisted tools.
- Sensitive operations require the documented approval control.
- Policy violations fail validation and are visible in audit and operational status.

## Exit Criteria

M12 is complete when the curated catalog, least-privilege policy enforcement, test coverage, audit controls, and documentation are verified.

## Related Documentation

- [Roadmap](../../../ROADMAP.md)
- [M06 MCP milestone](M06-MCP.md)
