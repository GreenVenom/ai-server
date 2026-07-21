---
title: Troubleshooting MCP
document: Runbook
status: Active
created: 2026-07-17
updated: 2026-07-21
platform_version: v0.6.0
owner: GreenVenom
---

# Troubleshooting MCP

## Purpose

Diagnose local MCP registration, authorization, and acceptance-test failures.

## Prerequisites

Access to the OpenClaw configuration and the platform operational scripts is required.

## Procedure

When tools appear in the aggregate probe but not to an agent, inspect:

```bash
openclaw config get tools.sandbox.tools --json
```

A registered tool can still be removed by sandbox policy. For local-model acceptance runs, use isolated sessions, `--thinking low`, and a 600-second timeout.

## Validation

After correcting configuration, reload MCP runtimes and confirm two servers, eight tools, and zero diagnostics.

## Related documentation

- [Registering an MCP server](Registering-an-MCP-Server.md)
- [MCP operations](MCP-Operations.md)
