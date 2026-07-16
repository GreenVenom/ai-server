# OpenClaw Current State

## Summary

OpenClaw is operational as a local-only agent platform using Ollama and Docker sandboxing.

## Versions

```text
OpenClaw        2026.7.1
Node.js         26.5.0
npm             11.17.0
Ollama          0.31.2
Docker Desktop  4.82.0
Docker Engine   29.6.1
```

## Gateway

```text
Service:        LaunchAgent
Status:         loaded and running
Bind:           127.0.0.1 and ::1
Port:           18789
Authentication: token
```

## Models

```text
Primary:  ollama/gemma4:12b
Fallback: ollama/qwen3:14b
```

## Agent

```text
Agent:            main
Workspace:        /Users/openclaw/server/workspaces/main
Sandbox backend:  Docker
Workspace access: read-write
Elevated:         disabled
```

## Docker

Verified:

```text
docker version
docker info
docker run --rm hello-world
```

Gateway socket override:

```text
OPENCLAW_DOCKER_SOCKET=/Users/openclaw/.docker/run/docker.sock
```

Sandbox image:

```text
openclaw-sandbox:bookworm-slim
```

## Functional Checks Completed

```text
[x] Dashboard opens locally
[x] Gateway responds
[x] Agent produces local model response
[x] Docker sandbox starts
[x] Productive workspace mounted read-write
[x] Agent writes a file
[x] Host sees the generated file
[x] Test file removed successfully
```

## Known Non-Blocking Items

- `operator.read` is not granted to the current diagnostic client.
- `gateway.trustedProxies` is unset because no reverse proxy exists.
- Docker Desktop must be available in the logged-in `openclaw` GUI session.
- Reboot persistence has not yet been fully validated.
- OpenClaw has not yet been integrated into platform operations scripts.
