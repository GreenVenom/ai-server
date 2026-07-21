---
title: MCP Architecture
document: Architecture
status: Active
created: 2026-07-17
updated: 2026-07-21
platform_version: v0.6.0
owner: GreenVenom
---

# MCP Architecture

## Purpose

Define the local Model Context Protocol boundary for approved, read-only platform capabilities.

## Design

M06 provides two local stdio MCP servers from `~/server/services/mcp/.venv`:

- `obsidian-retrieval` exposes approved indexed-vault retrieval.
- `platform-status` exposes approved platform inspection.

The production contract is exactly two servers, eight tools, and zero diagnostics. Obsidian tools use loopback Ollama and Qdrant. Platform tools execute only predetermined commands with `shell=False`, a restricted environment, timeouts, and bounded output.

## Constraints

- No MCP server binds to a TCP port.
- Tools are read-only and use strict schemas.
- OpenClaw tool filters and sandbox allowlists must name each exposed tool explicitly.
- Tools cannot accept arbitrary commands, paths, hosts, URLs, or executables.

## Related documentation

- [MCP development standards](../engineering/MCP-Development-Standards.md)
- [M06 milestone record](../operations/milestones/M06-MCP.md)
- [MCP operations](../operations/MCP-Operations.md)
