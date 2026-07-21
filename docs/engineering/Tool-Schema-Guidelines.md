---
title: Tool Schema Guidelines
document: Standard
status: Active
created: 2026-07-17
updated: 2026-07-21
platform_version: v0.6.0
owner: GreenVenom
---

# Tool Schema Guidelines

## Purpose

Define input-schema constraints for MCP tools that protect the local execution boundary.

## Standards

Use enums or literals for bounded choices, safe identifier validation for IDs,
and numeric limits for result counts. Request models must use
`extra="forbid"`. Production inspection tools must not expose generic
`command`, `path`, `url`, `host`, `script`, or `args` fields.

## Related documentation

- [MCP development standards](MCP-Development-Standards.md)
- [Tool authorization architecture](../architecture/Tool-Authorization-Architecture.md)
