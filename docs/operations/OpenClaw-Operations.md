---
title: OpenClaw Operations
document: Operation
status: Active
created: 2026-07-17
updated: 2026-07-17
platform_version: v0.3.0
owner: Personal AI Platform maintainers
---

# OpenClaw Operations

## Standard Commands

```bash
openclaw gateway status
openclaw models status
openclaw sandbox list
openclaw sandbox explain --agent main
openclaw security audit --deep
```

## Platform Operations

```bash
~/server/scripts/status.sh
~/server/scripts/doctor.sh
~/server/scripts/health.sh
~/server/scripts/verify.sh
```

Expected:

```text
status.sh  PASS
doctor.sh  31/31
health.sh  30/30
verify.sh  26/26
```

## Recovery

```bash
openclaw gateway restart
openclaw gateway status
```

If token or LaunchAgent state drifts:

```bash
openclaw gateway install --force
openclaw gateway restart
```

## Docker

```bash
docker info
docker image inspect openclaw-sandbox:bookworm-slim
readlink /var/run/docker.sock
```

Expected socket target:

```text
/Users/openclaw/.docker/run/docker.sock
```

## Reboot Behavior

After reboot, log into the `openclaw` account. Docker Desktop starts automatically on user login. Then run `verify.sh`.

## Related documentation

- [Documentation map](../README.md)
