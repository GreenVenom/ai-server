---
title: M03 — OpenClaw Platform
document: Milestone
status: Complete
created: 2026-07-17
updated: 2026-07-17
platform_version: v0.3.0
owner: GreenVenom
---

# M03 — OpenClaw Platform

| Field | Value |
| --- | --- |
| Status | Complete |
| Platform version | v0.3.0 |
| Milestone | M03 |

## Objective

Deploy OpenClaw as the local-first orchestration and agent layer for the Personal AI Platform.

## Runtime

```text
OpenClaw        2026.7.1 (2d2ddc4)
Node.js         26.5.0
npm             11.17.0
Ollama          0.31.2
Docker Desktop  4.82.0
Docker Engine   29.6.1
Host            Mac mini M4 Pro
Memory          24 GB
Service user    openclaw
```

## Gateway

```text
LaunchAgent: ~/Library/LaunchAgents/ai.openclaw.gateway.plist
Bind:        127.0.0.1 and ::1
Port:        18789
Auth:        token
Tailnet:     off
```

## Models

```text
Primary:   ollama/gemma4:12b
Fallback:  ollama/qwen3:14b
Embedding: nomic-embed-text:latest
```

## Security Baseline

- loopback-only Gateway
- token authentication
- insecure Control UI auth disabled
- sandbox mode enabled for all sessions
- elevated execution disabled
- web and browser tools disabled
- cloud memory search disabled
- dedicated productive workspace
- zero critical findings in deep audit

## Docker Sandbox

```text
OPENCLAW_DOCKER_SOCKET=/Users/openclaw/.docker/run/docker.sock
Image: openclaw-sandbox:bookworm-slim
```

## Workspace

```text
Host:      /Users/openclaw/server/workspaces/main
Container: /workspace
Mode:      read-write
```

Agent file creation was verified from the host.

## Operations Integration

Updated:

```text
scripts/status.sh
scripts/doctor.sh
scripts/health.sh
scripts/verify.sh
scripts/lib/services.sh
scripts/lib/checks.sh
scripts/lib/results.sh
scripts/lib/logging.sh
```

## Final Validation

```text
status.sh  PASS
doctor.sh  31/31 PASS
health.sh  30/30 PASS
verify.sh  26/26 PASS
```

## Reboot Persistence

Verified after reboot and login:

- Tailscale available
- Ollama available
- Docker Desktop started automatically on user login
- OpenClaw Gateway available
- RPC probe passed
- sandbox available
- workspace write succeeded
- all operations scripts passed

## Acceptance Criteria

```text
[x] OpenClaw installed
[x] Gateway LaunchAgent operational
[x] Gateway loopback-only
[x] Token authentication working
[x] Local Ollama models configured
[x] Docker sandbox operational
[x] Productive workspace verified
[x] Security baseline enforced
[x] Operations scripts integrated
[x] Reboot persistence validated
[x] Docker auto-start on user login validated
```

M03 is complete. See the [v0.3.0 release notes](../releases/v0.3.0.md).

## Related documentation

- [Documentation map](../README.md)
