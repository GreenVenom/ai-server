# OpenClaw Architecture

## Purpose

OpenClaw provides the orchestration and agent layer for the Personal AI Platform. It sits above the production Ollama runtime and below future integrations such as Qdrant, Obsidian, MCP servers, and external channels.

## Logical Architecture

```text
User
  ↓
OpenClaw Dashboard
  ↓
OpenClaw Gateway
  ↓
Main Agent
  ↓
Docker Sandbox
  ↓
Productive Workspace
```

Model execution path:

```text
OpenClaw Agent
    ↓
Ollama Provider
    ↓
ollama/gemma4:12b
    ↓
fallback: ollama/qwen3:14b
```

## Host Components

```text
CLI:              /opt/homebrew/bin/openclaw
Configuration:    ~/.openclaw/openclaw.json
Environment:      ~/.openclaw/.env
Agent state:      ~/.openclaw/agents/main/
Gateway service:  ~/Library/LaunchAgents/ai.openclaw.gateway.plist
Gateway logs:     ~/Library/Logs/openclaw/
Productive data:  ~/server/workspaces/main
```

## Gateway Boundary

The Gateway listens only on loopback:

```text
127.0.0.1:18789
[::1]:18789
```

No reverse proxy or direct Tailnet exposure is configured.

## Authentication

The Gateway uses token authentication. A token mismatch after onboarding was repaired by reinstalling or refreshing the LaunchAgent from the current configuration and restarting the Gateway.

## Model Layer

```text
Primary:  ollama/gemma4:12b
Fallback: ollama/qwen3:14b
Endpoint: http://127.0.0.1:11434
```

Only local Ollama model references remain in the agent model allowlist.

## Sandbox Layer

```text
agents.defaults.sandbox.mode = all
tools.elevated.enabled = false
```

Web and browser tools are disabled globally.

## Docker Integration

```text
OPENCLAW_DOCKER_SOCKET=/Users/openclaw/.docker/run/docker.sock
Sandbox image: openclaw-sandbox:bookworm-slim
```

## Workspace Boundary

```text
Host:      /Users/openclaw/server/workspaces/main
Container: /workspace
Mode:      read-write
```

The main agent does not receive broad access to `~/server`, `~/.ssh`, or `~/.openclaw`.

## Security Principles

- local-first inference
- loopback-only control plane
- explicit local model allowlist
- sandbox all agent sessions
- no elevated host execution
- no uncontrolled web input
- dedicated workspaces instead of broad home access
