---
title: Testing MCP Tools
document: Runbook
status: Active
created: 2026-07-17
updated: 2026-07-21
platform_version: v0.6.0
owner: GreenVenom
---

# Testing MCP Tools

## Purpose

Validate MCP schemas, safety boundaries, policy enforcement, and agent-visible behavior.

## Prerequisites

Use the project virtual environment and ensure any live dependencies required by integration tests are healthy.

## Procedure

Run schema and boundary unit tests, live integration tests, exact OpenClaw policy tests, abuse tests, and end-to-end agent acceptance tests.

## Validation

Confirm the production contract of two servers, eight tools, and zero diagnostics. Keep live acceptance output local because it can contain session paths and indexed note content.

## Troubleshooting

Use [MCP operations](MCP-Operations.md) for doctor, probe, and platform-level validation.

## Related documentation

- [MCP development standards](../engineering/MCP-Development-Standards.md)
- [MCP operations](MCP-Operations.md)
