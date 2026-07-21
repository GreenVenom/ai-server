---
title: MCP Development Standards
document: Standard
status: Active
created: 2026-07-17
updated: 2026-07-21
platform_version: v0.6.0
owner: GreenVenom
---

# MCP Development Standards

## Purpose

Set the required security and validation practices for local MCP services.

## Standards

- Default to read-only tools and local stdio transport.
- Use strict schemas and reject unknown fields.
- Never accept arbitrary commands, paths, hosts, URLs, or executables.
- Use `shell=False`, restricted environments, timeouts, and bounded output.
- Return versioned structured envelopes and sanitized errors.
- Add unit, integration, abuse, policy, and agent acceptance tests.
- Update registration, sandbox policy, operational checks, and documentation together.

## Related documentation

- [MCP architecture](../architecture/MCP-Architecture.md)
- [Testing MCP tools](../operations/Testing-MCP-Tools.md)
- [M06 milestone record](../operations/milestones/M06-MCP.md)
