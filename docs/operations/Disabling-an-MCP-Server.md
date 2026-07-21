---
title: Disabling an MCP Server
document: Runbook
status: Active
created: 2026-07-17
updated: 2026-07-21
platform_version: v0.6.0
owner: GreenVenom
---

# Disabling an MCP Server

## Purpose

Safely remove an MCP server from the production inventory.

## Prerequisites

Confirm the intended post-change server and tool inventory before making configuration changes.

## Procedure

Remove the registration, remove its namespaced tools from sandbox policy and `scripts/lib/mcp.sh`, then reload MCP runtimes. Do not leave orphaned allowlist entries.

## Validation

Run doctor, probe, status, health, and verification checks and confirm they report the newly intended inventory.

## Related documentation

- [Registering an MCP server](Registering-an-MCP-Server.md)
- [MCP operations](MCP-Operations.md)
