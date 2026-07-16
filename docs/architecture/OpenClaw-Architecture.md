# OpenClaw Architecture

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
/workspace
  ↓
~/server/workspaces/main
```

Model path:

```text
OpenClaw
  ↓
Ollama
  ↓
ollama/gemma4:12b
  ↓
fallback: ollama/qwen3:14b
```

## Host Components

```text
CLI:        /opt/homebrew/bin/openclaw
Config:     ~/.openclaw/openclaw.json
Environment: ~/.openclaw/.env
Gateway:    ~/Library/LaunchAgents/ai.openclaw.gateway.plist
Workspace:  ~/server/workspaces/main
Image:      openclaw-sandbox:bookworm-slim
```

## Trust Boundary

Only the productive workspace is mounted read-write. Operational, configuration, model, backup, SSH, and OpenClaw state paths are not directly exposed to the agent.

## Dependencies

```text
OpenClaw Gateway
  ├── Ollama
  ├── Docker Desktop
  └── main workspace
```

Docker Desktop starts automatically when the `openclaw` account logs in.
