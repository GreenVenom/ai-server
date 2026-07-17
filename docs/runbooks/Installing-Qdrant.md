---
title: Installing Qdrant
document: Runbook
status: Active
created: 2026-07-17
updated: 2026-07-17
platform_version: v0.4.0
owner: GreenVenom
---

# Installing Qdrant

## Purpose

Deploy the M04 Qdrant service with its validated local-only, persistent configuration.

## Prerequisites

- Run as the `openclaw` standard user.
- Docker Desktop is installed and running.
- Docker Compose is available.
- Ports 6333 and 6334 are unused.
- Backup directories exist.
- The image version has been deliberately selected.

## Required Directories

```bash
mkdir -p   "$HOME/server/docker/qdrant"   "$HOME/server/backups/qdrant/snapshots"   "$HOME/server/backups/qdrant/manifests"
```

## Deployment contract

The Compose service must use:

```text
qdrant/qdrant:v1.18.2
restart: always
127.0.0.1:6333:6333
127.0.0.1:6334:6334
personal-ai-qdrant-storage:/qdrant/storage
host snapshot bind:/qdrant/snapshots
telemetry disabled
no-new-privileges
```

## Procedure

```bash
cd "$HOME/server/docker/qdrant"
docker compose config
docker compose pull
docker compose up -d
```

## Wait for Readiness

```bash
for attempt in {1..30}; do
  if curl --fail --silent       http://127.0.0.1:6333/readyz >/dev/null 2>&1
  then
    printf 'Qdrant became ready after %s checks.
' "$attempt"
    break
  fi
  sleep 2
done
```

## Verify Runtime

```bash
docker compose ps

docker inspect personal-ai-qdrant   --format 'status={{.State.Status}} health={{.State.Health.Status}} restart={{.HostConfig.RestartPolicy.Name}}'

docker inspect personal-ai-qdrant   --format '{{range .Mounts}}{{println .Type .Name .Source .Destination}}{{end}}'
```

Expected live mount:

```text
volume personal-ai-qdrant-storage ... /qdrant/storage
```

Expected snapshot mount:

```text
bind ... /qdrant/snapshots
```

## Verify Network Boundary

```bash
lsof -nP -iTCP:6333 -sTCP:LISTEN
lsof -nP -iTCP:6334 -sTCP:LISTEN
```

Both ports must bind to `127.0.0.1`.

## Validation

```bash
"$HOME/server/scripts/health.sh"
"$HOME/server/scripts/verify.sh"
```


## Troubleshooting

If readiness, networking, or container validation fails, follow [Troubleshooting Qdrant](Troubleshooting-Qdrant.md).

## Related documentation

- [Qdrant operations](../operations/Qdrant-Operations.md)
- [ADR-0011](../decisions/ADR-0011-Deploy-Qdrant-as-Docker-Compose-Service.md)
