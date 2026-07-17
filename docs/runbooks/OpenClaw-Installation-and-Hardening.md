---
title: OpenClaw Installation and Hardening
document: Runbook
status: Active
created: 2026-07-17
updated: 2026-07-17
platform_version: v0.3.0
owner: Personal AI Platform maintainers
---

# OpenClaw Installation and Hardening

## Installation

```bash
npm install -g openclaw@latest
```

Verify:

```bash
openclaw --version
which openclaw
npm list -g --depth=0 openclaw
```

## Onboarding Choices

```text
Setup:              QuickStart
Gateway bind:       loopback
Gateway auth:       token
Tailscale exposure: off
Provider:           Ollama
Default model:      gemma4:12b
Search provider:    skipped
```

## Gateway Repair

```bash
openclaw gateway install --force
openclaw gateway restart
openclaw gateway status
```

## Model Configuration

```text
Primary:  ollama/gemma4:12b
Fallback: ollama/qwen3:14b
```

The accidental `openai/qwen3:14b` allowlist entry was removed.

## Hardening Commands

```bash
openclaw config set agents.defaults.memorySearch.enabled false
openclaw config set agents.defaults.sandbox.mode all
openclaw config set tools.deny '["group:web","browser"]'
openclaw config set gateway.controlUi.allowInsecureAuth false
openclaw config set tools.elevated.enabled false
```

## Productive Workspace

```bash
openclaw config set agents.defaults.workspace "/Users/openclaw/server/workspaces/main"
openclaw config set agents.defaults.sandbox.workspaceAccess rw
```

## Docker Socket

Create `~/.openclaw/.env`:

```text
OPENCLAW_DOCKER_SOCKET=/Users/openclaw/.docker/run/docker.sock
```

Then:

```bash
chmod 600 ~/.openclaw/.env
openclaw gateway restart
```

## Sandbox Image

The required local image is:

```text
openclaw-sandbox:bookworm-slim
```

It must include Python 3 for OpenClaw write and edit helpers.

## Validate

```bash
openclaw config validate
openclaw gateway status
openclaw models status
openclaw sandbox explain --agent main
openclaw security audit --deep
```

## Related documentation

- [Documentation map](../README.md)
