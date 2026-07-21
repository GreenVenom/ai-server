---
title: Upgrading the MCP SDK
document: Runbook
status: Active
created: 2026-07-17
updated: 2026-07-21
platform_version: v0.6.0
owner: GreenVenom
---

# Upgrading the MCP SDK

## Purpose

Upgrade the MCP SDK while preserving the approved production tool boundary.

## Prerequisites

Perform the upgrade on a branch and review upstream protocol changes before deployment.

## Procedure

Recreate the environment, install the updated dependency, and run compilation, unit tests, integration tests, MCP doctor and probe, all ten agent acceptance scenarios, and the platform operational suite.

## Validation

Confirm the expected production inventory of two servers, eight tools, and zero diagnostics. Record material protocol changes in an ADR.

## Related documentation

- [Testing MCP tools](Testing-MCP-Tools.md)
- [MCP development standards](../engineering/MCP-Development-Standards.md)
