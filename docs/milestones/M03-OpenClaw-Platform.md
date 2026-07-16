# M03 — OpenClaw Platform

**Status:** In Progress  
**Checkpoint:** Core deployment, local model integration, security hardening, and productive sandbox workspace complete  
**Next Work:** Integrate OpenClaw into `doctor.sh`, `status.sh`, `health.sh`, and `verify.sh`

## Objective

Deploy OpenClaw as the orchestration and agent layer for the Personal AI Platform while preserving the platform's local-first, least-privilege, and reproducible operating model.

OpenClaw is deployed on top of the production Ollama runtime completed in M02.

## Current Runtime

```text
OpenClaw        2026.7.1 (2d2ddc4)
Node.js         26.5.0
npm             11.17.0
Ollama          0.31.2
Docker Desktop  4.82.0
Docker Engine   29.6.1
Host            Mac mini M4 Pro
Memory          24 GB unified memory
Service user    openclaw
```

## Installation

OpenClaw was installed globally with npm under the `openclaw` service account.

```text
Binary:  /opt/homebrew/bin/openclaw
Package: /opt/homebrew/lib/node_modules/openclaw
```

## Gateway Deployment

```text
Service:      ~/Library/LaunchAgents/ai.openclaw.gateway.plist
Working dir:  ~/.openclaw
Port:         18789
Bind:         127.0.0.1 and ::1 only
Authentication: token
Tailscale exposure: off
```

The Gateway is intentionally not exposed directly to the LAN or Tailnet.

## Model Configuration

```text
Primary:  ollama/gemma4:12b
Fallback: ollama/qwen3:14b
```

The default model was selected because it performed better in the M02 benchmark results. OpenAI memory search was disabled because no cloud memory provider is required at this stage.

## Verified Functional Path

```text
OpenClaw Dashboard
    ↓
OpenClaw Gateway
    ↓
Ollama provider
    ↓
ollama/gemma4:12b
    ↓
Successful local response
```

A Gateway token mismatch encountered after onboarding was repaired by refreshing and restarting the installed Gateway service.

## Security Baseline

Completed:

- Gateway bound to loopback.
- Token authentication enabled.
- Insecure Control UI authentication disabled.
- Web and browser tools disabled.
- Sandbox mode enabled for all agent sessions.
- Elevated execution explicitly disabled.
- OpenAI memory search disabled.
- Stray `openai/qwen3:14b` model entry removed.
- Security audit reduced to zero critical findings.

Accepted warnings:

- `gateway.trusted_proxies_missing`: accepted because no reverse proxy is configured.
- `gateway.probe_failed: missing scope operator.read`: accepted as degraded diagnostics, not a runtime failure.

## Sandbox Runtime

Docker Desktop provides the sandbox backend. Gateway Docker access is configured through `~/.openclaw/.env`:

```text
OPENCLAW_DOCKER_SOCKET=/Users/openclaw/.docker/run/docker.sock
```

The local sandbox image is:

```text
openclaw-sandbox:bookworm-slim
```

## Productive Workspace

```text
Host:      ~/server/workspaces/main
Container: /workspace
Access:    read-write
```

The agent successfully created a test file in this workspace and the file was verified from the host.

## Workspace Structure

```text
~/server/workspaces/
├── main/
├── secondary/
├── read-only/
└── shared/
```

Only `main/` is currently active.

## Current Acceptance Status

```text
[x] OpenClaw installed
[x] Version recorded
[x] Gateway installed as LaunchAgent
[x] Gateway bound to loopback
[x] Gateway token authentication working
[x] Ollama provider connected
[x] gemma4:12b configured as primary
[x] qwen3:14b configured as fallback
[x] First dashboard response successful
[x] Memory search cloud dependency disabled
[x] Sandbox mode enabled
[x] Web/browser tools disabled
[x] Elevated execution disabled
[x] Security audit has zero critical findings
[x] Docker socket available to Gateway
[x] Sandbox image built
[x] Dedicated productive workspace configured
[x] Read-write workspace mount verified
[x] Agent file creation verified

[ ] OpenClaw checks added to doctor.sh
[ ] OpenClaw checks added to status.sh
[ ] OpenClaw checks added to health.sh
[ ] OpenClaw checks added to verify.sh
[ ] Reboot persistence verified
[ ] M03 documentation finalized
```

## Next Step

Integrate OpenClaw into the platform operational scripts, then perform a reboot-persistence validation covering Docker Desktop, Ollama, the Gateway, dashboard response, sandbox creation, and workspace writes.
