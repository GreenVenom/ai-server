---
title: Tool Authorization Architecture
document: Architecture
status: Active
created: 2026-07-17
updated: 2026-07-21
platform_version: v0.6.0
owner: GreenVenom
---

# Tool Authorization Architecture

## Purpose

Define the layered controls that restrict MCP tools to their approved production boundary.

## Design

Authorization is layered:

1. The server exposes only approved functions.
2. OpenClaw `toolFilter.include` uses exact server-local names.
3. Sandbox `alsoAllow` uses exact namespaced names.
4. Strict request schemas reject unknown fields.
5. Runtime allowlists restrict vaults and components.
6. Operational scripts verify the exact aggregate inventory.

Server registration alone is not sufficient because sandboxed sessions apply a
separate tool-policy gate.

## Constraints

Every layer must use the same exact tool inventory; server registration alone does not authorize a tool for sandboxed agents.

## Related documentation

- [MCP architecture](MCP-Architecture.md)
- [MCP development standards](../engineering/MCP-Development-Standards.md)
