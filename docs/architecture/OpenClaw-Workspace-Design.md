---
title: OpenClaw Workspace Design
document: Architecture
status: Active
created: 2026-07-17
updated: 2026-07-17
platform_version: v0.3.0
owner: Personal AI Platform maintainers
---

# OpenClaw Workspace Design

## Purpose

Workspaces provide controlled host storage for OpenClaw agents without exposing the complete server tree or user home directory.

## Root

```text
~/server/workspaces/
```

## Planned Structure

```text
~/server/workspaces/
├── main/
├── secondary/
├── read-only/
└── shared/
```

## Main Workspace

```text
~/server/workspaces/main
```

Purpose:

- primary productive workspace
- agent-generated files
- coding and editing tasks
- controlled read-write operations

Configuration:

```text
agents.defaults.workspace:
  /Users/openclaw/server/workspaces/main

agents.defaults.sandbox.workspaceAccess:
  rw
```

Mount:

```text
/Users/openclaw/server/workspaces/main
    → /workspace
    rw
```

## Secondary Workspace

Reserved for a future secondary agent, isolated experiments, or alternate model workflows. It is not currently mounted to the main agent.

## Read-Only Workspace

Reserved for reference material that an agent may inspect but should not modify. It is not currently mounted.

## Shared Workspace

Reserved for intentionally shared artifacts between future agents. It should remain small and deliberate.

## Excluded Paths

The main agent should not receive direct access to:

```text
~/server/config
~/server/services
~/server/scripts
~/server/data/models
~/server/backups
~/.ssh
~/.openclaw
```

## Verification

The main agent created `workspace-test.txt` in `~/server/workspaces/main`, the host verified the expected content, and the test file was removed.

## Related documentation

- [Documentation map](../README.md)
