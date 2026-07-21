---
title: MCP Operations
document: Operation
status: Active
created: 2026-07-17
updated: 2026-07-21
platform_version: v0.6.0
owner: GreenVenom
---

# MCP Operations

## Summary

Operate and validate the two local MCP services that expose eight approved read-only tools.

## Environment

Run these checks on the production host after OpenClaw and the MCP services are installed.

```bash
openclaw mcp doctor
openclaw mcp probe --json | python3 -m json.tool
openclaw mcp reload

~/server/scripts/status.sh
~/server/scripts/health.sh
~/server/scripts/verify.sh
```

## Current state

The expected production inventory is two servers, eight tools, and zero diagnostics.

## Validation

```bash
cd ~/server/services/mcp
.venv/bin/python -m pytest -v -m 'not integration'
.venv/bin/python -m pytest -v -m integration
```

## Related documentation

- [MCP architecture](../architecture/MCP-Architecture.md)
- [Testing MCP tools](Testing-MCP-Tools.md)
- [Troubleshooting MCP](Troubleshooting-MCP.md)
