---
title: M06 - MCP Services
document: Milestone
status: Complete
created: 2026-07-17
updated: 2026-07-21
platform_version: v0.6.0
owner: GreenVenom
---

# M06 - MCP Services

## Objective

Expose approved platform capabilities through narrow, local-first MCP interfaces while preserving the M05 retrieval boundary and least-privilege controls.

## Scope

M06 delivers local stdio MCP services for read-only Obsidian retrieval and platform inspection. Network listeners, arbitrary command execution, arbitrary filesystem access, and write-capable tools are out of scope.

## Deliverables

- Two local stdio MCP servers: `obsidian-retrieval` and `platform-status`.
- Four approved tools per server, for an exact inventory of eight read-only tools.
- Strict schemas, sanitized errors, explicit OpenClaw filters, and sandbox allowlists.
- Restricted subprocess execution with fixed commands, `shell=False`, bounded output, and timeouts.
- Unit, integration, security, policy, and ten-scenario agent acceptance coverage.
- Status, health, and verification integration.

## Validation

The production validation contract is two servers, eight tools, and zero diagnostics. M06 acceptance recorded 10/10 agent scenarios, 56/56 health checks, and 45/45 verification checks.

## Exit criteria

Complete. The documented MCP boundary, tests, and operational checks meet the M06 acceptance contract.

## Related documentation

- [MCP architecture](../../architecture/MCP-Architecture.md)
- [MCP development standards](../../engineering/MCP-Development-Standards.md)
- [M06 release notes](../../releases/v0.6.0.md)
- [Roadmap](../../../ROADMAP.md)
