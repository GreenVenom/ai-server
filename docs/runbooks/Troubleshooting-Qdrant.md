---
title: Troubleshooting Qdrant
document: Runbook
status: Active
created: 2026-07-17
updated: 2026-07-17
platform_version: v0.4.0
owner: Personal AI Platform maintainers
---

# Troubleshooting Qdrant

## Purpose

Diagnose and safely recover common Qdrant service, data, and validation failures.

## Prerequisites

- Access to the `openclaw` account and Docker Desktop diagnostics.

## Procedure

Use the checks and recovery actions below, then complete the validation steps at the end of this runbook.

## Troubleshooting

### Qdrant is unreachable

### Symptoms

```text
curl: failed to connect to 127.0.0.1 port 6333
```

### Checks

```bash
docker info
docker ps -a --filter name=personal-ai-qdrant
docker inspect personal-ai-qdrant   --format 'status={{.State.Status}} exit={{.State.ExitCode}} error={{.State.Error}} restart={{.HostConfig.RestartPolicy.Name}}'
docker logs --tail 200 personal-ai-qdrant
```

### Recovery

```bash
docker start personal-ai-qdrant
```

If the container does not exist:

```bash
cd "$HOME/server/docker/qdrant"
docker compose up -d
```

## Docker Desktop Is Not Running

Qdrant cannot run before Docker Desktop is available.

```bash
docker info
```

Log in to the `openclaw` account and allow Docker Desktop to start.

## Container Remains Exited After Docker Restart

The production policy must be:

```text
restart=always
```

Check:

```bash
docker inspect personal-ai-qdrant   --format '{{.HostConfig.RestartPolicy.Name}}'
```

If incorrect, update Compose and recreate:

```bash
cd "$HOME/server/docker/qdrant"
docker compose up -d --force-recreate
```

## Validation Collection Missing

```bash
curl --fail --silent   http://127.0.0.1:6333/collections/m04_validation |
python3 -m json.tool
```

A 404 means the collection is missing. Restore it from a validated snapshot or recreate the validation corpus.

## Collection Not Green

Inspect collection metadata and Qdrant logs. Do not continue application indexing until the collection returns to `green`.

## Wrong Vector Dimension

The `text-dense` vector requires 768 dimensions. Qdrant will reject shorter or longer vectors.

Confirm the embedding model:

```text
nomic-embed-text:latest
```

Confirm the collection vector:

```text
text-dense: 768, Cosine
```

Do not truncate or pad vectors. Create a compatible collection or use the correct embedding model.

## Data Missing After Container Recreation

Check the mount:

```bash
docker inspect personal-ai-qdrant   --format '{{range .Mounts}}{{println .Type .Name .Source .Destination}}{{end}}'
```

Expected:

```text
volume personal-ai-qdrant-storage ... /qdrant/storage
```

If a different or empty volume is mounted, stop writes and inspect the Compose project and volume inventory before recreating anything.

Never run:

```bash
docker compose down -v
```

unless deliberate data destruction is intended.

## Snapshot Restore Fails

Check:

- snapshot checksum;
- Qdrant version compatibility;
- target collection name;
- file permissions;
- snapshot filename and manifest pairing;
- container logs.

Restore into a new collection and preserve the original artifacts.

## Platform Scripts Disagree

Run:

```bash
bash -n "$HOME/server/scripts/status.sh"
bash -n "$HOME/server/scripts/health.sh"
bash -n "$HOME/server/scripts/verify.sh"

grep -E '^# Script:|print_header '   "$HOME/server/scripts/status.sh"   "$HOME/server/scripts/health.sh"   "$HOME/server/scripts/verify.sh"
```

Expected headers:

```text
Platform Status
Platform Health
Production Verification
```


## Validation

After recovery, run status.sh, health.sh, and erify.sh; Qdrant must be healthy, loopback-only, and return the expected validation collection state.

## Related documentation

- [Qdrant operations](../operations/Qdrant-Operations.md)
- [Installing Qdrant](Installing-Qdrant.md)
- [Restoring Qdrant](Restoring-Qdrant.md)
