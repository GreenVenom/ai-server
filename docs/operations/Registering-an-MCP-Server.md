---
title: Registering an MCP Server
document: Runbook
status: Active
created: 2026-07-17
updated: 2026-07-21
platform_version: v0.6.0
owner: GreenVenom
---

# Registering an MCP Server

## Purpose

Register an approved local MCP server without widening the execution boundary.

## Prerequisites

The server package, exact tool inventory, and required sandbox policy changes have been reviewed.

## Procedure

Pin the Python executable, module, working directory, connection timeout, request timeout, and exact tool filter. Add every namespaced tool to sandbox policy and the operational inventory. Wildcards are prohibited in production.

## Validation

Reload MCP runtimes and confirm doctor and probe report the intended server and tool inventory with zero diagnostics.

## Troubleshooting

If a tool is registered but unavailable to an agent, inspect the sandbox policy as described in [Troubleshooting MCP](Troubleshooting-MCP.md).

## Related documentation

- [MCP development standards](../engineering/MCP-Development-Standards.md)
- [MCP operations](MCP-Operations.md)
