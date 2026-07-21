---
title: Installing MCP Services
document: Runbook
status: Active
created: 2026-07-17
updated: 2026-07-21
platform_version: v0.6.0
owner: GreenVenom
---

# Installing MCP Services

## Purpose

Install the local MCP service package and its approved OpenClaw integration.

## Prerequisites

The repository is available at `~/server`, the target host has Python 3.12 or later, and the approved OpenClaw configuration is available.

## Procedure

Copy `services/mcp` to `~/server/services/mcp`, create `.venv`, install `.[dev]`, apply the OpenClaw registration and exact sandbox allowlist, validate configuration, and reload MCP runtimes.

## Validation

Run MCP doctor and probe, the service tests, and platform status, health, and verification checks. The expected inventory is two servers, eight tools, and zero diagnostics.

## Troubleshooting

Use [Troubleshooting MCP](Troubleshooting-MCP.md) when a registered tool is not available to an agent.

## Related documentation

- [Registering an MCP server](Registering-an-MCP-Server.md)
- [MCP operations](MCP-Operations.md)
