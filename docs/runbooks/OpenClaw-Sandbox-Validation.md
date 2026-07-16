# OpenClaw Sandbox Validation

## Prerequisites

- Docker Desktop running as the `openclaw` user
- Docker API accessible without `sudo`
- Gateway running
- sandbox image present
- main workspace configured

## Docker Validation

```bash
docker version
docker info
docker run --rm hello-world
```

Verify socket:

```bash
ls -l /var/run/docker.sock
readlink /var/run/docker.sock
```

Expected target:

```text
/Users/openclaw/.docker/run/docker.sock
```

## OpenClaw Environment

```bash
grep '^OPENCLAW_DOCKER_SOCKET=' ~/.openclaw/.env
```

Expected:

```text
OPENCLAW_DOCKER_SOCKET=/Users/openclaw/.docker/run/docker.sock
```

## Sandbox Image

```bash
docker image inspect openclaw-sandbox:bookworm-slim
```

## Effective Policy

```bash
openclaw sandbox explain --agent main
```

Expected:

```text
runtime: sandboxed
mode: all
workspaceAccess: rw
backend: docker
elevated: false
```

Expected mount:

```text
/Users/openclaw/server/workspaces/main
    → /workspace
    rw
```

## Runtime Test

Ask the agent to create `workspace-test.txt` containing:

```text
OpenClaw productive workspace is working.
```

Verify:

```bash
openclaw sandbox list
cat ~/server/workspaces/main/workspace-test.txt
```

Cleanup:

```bash
rm ~/server/workspaces/main/workspace-test.txt
```

## Successful State

```text
[x] Sandbox container running
[x] Correct image
[x] Docker backend
[x] Main workspace mounted read-write
[x] Elevated execution disabled
[x] Agent file write successful
[x] Host file verification successful
```
