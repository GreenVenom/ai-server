---
title: Qdrant Operations
document: Operation
status: Active
created: 2026-07-17
updated: 2026-07-17
platform_version: v0.4.0
owner: Personal AI Platform maintainers
---

# Qdrant Operations

## Purpose

Operate, validate, upgrade, and recover the production Qdrant service delivered by M04.

## Service Summary

```text
Container        personal-ai-qdrant
Image            qdrant/qdrant:v1.18.2
Compose          ~/server/docker/qdrant/compose.yaml
REST             http://127.0.0.1:6333
gRPC             127.0.0.1:6334
Restart          always
Data volume      personal-ai-qdrant-storage
Snapshots        ~/server/backups/qdrant/snapshots
Manifests        ~/server/backups/qdrant/manifests
```

## Lifecycle Constraint

Qdrant runs inside Docker Desktop. Docker Desktop starts after the `openclaw` account logs in. Qdrant is therefore available after login, not before the macOS user session exists.

## Routine Commands

### Status

```bash
cd "$HOME/server/docker/qdrant"
docker compose ps
docker inspect personal-ai-qdrant   --format 'status={{.State.Status}} health={{.State.Health.Status}} restart={{.HostConfig.RestartPolicy.Name}}'
```

### Start

```bash
cd "$HOME/server/docker/qdrant"
docker compose up -d
```

### Stop

```bash
docker stop personal-ai-qdrant
```

Because the policy is `always`, an intentionally stopped container will return the next time Docker Desktop starts.

### Restart

```bash
cd "$HOME/server/docker/qdrant"
docker compose restart qdrant
```

### Recreate Without Deleting Data

```bash
cd "$HOME/server/docker/qdrant"
docker compose down
docker compose up -d
```

Never add `-v` unless the explicit objective is to destroy the live named volume.

### Logs

```bash
docker logs --tail 200 personal-ai-qdrant
docker logs --follow personal-ai-qdrant
```

### Version

```bash
curl --fail --silent http://127.0.0.1:6333/ |
python3 -m json.tool
```

### Collections

```bash
curl --fail --silent http://127.0.0.1:6333/collections |
python3 -m json.tool
```

## Health and Verification

```bash
"$HOME/server/scripts/status.sh"
"$HOME/server/scripts/health.sh"
"$HOME/server/scripts/verify.sh"
```

Expected current results:

```text
status.sh   WARN only when no on-demand OpenClaw sandbox is running
health.sh   45 passed, 0 failed
verify.sh   44 passed, 0 failed
```

Dedicated Qdrant persistence test:

```bash
"$HOME/server/scripts/tests/qdrant-persistence-check.sh"
```

Expected:

```text
Passed: 12
Failed: 0
```

## Backup and Restore Test

```bash
"$HOME/server/scripts/tests/qdrant-backup-restore-test.sh"
```

Expected validated result:

```text
Passed: 29
Failed: 0
```

The test retains the portable snapshot and manifest and removes its disposable restore collection. By default it also deletes the internal Qdrant snapshot after successful validation.

## Snapshot Cleanup

Preview:

```bash
"$HOME/server/scripts/maintenance/qdrant-snapshot-cleanup.sh"
```

Apply:

```bash
DRY_RUN=false   "$HOME/server/scripts/maintenance/qdrant-snapshot-cleanup.sh"
```

Defaults:

```text
Internal retention  7 days
Portable retention  30 days
Dry run             enabled
Orphan deletion     disabled
```

## Upgrade Procedure

1. Review Qdrant release notes.
2. Create and validate a portable snapshot.
3. Record current image tag and digest.
4. Change the pinned image in Compose.
5. Pull the new image.
6. Recreate the container without deleting the named volume.
7. Run `status.sh`, `health.sh`, and `verify.sh`.
8. Run persistence and backup/restore tests.
9. Roll back to the prior image if validation fails.
10. Update ADRs, version inventory, and release notes.

## Rollback Procedure

```bash
cd "$HOME/server/docker/qdrant"
# Restore the prior pinned image in compose.yaml.
docker compose pull
docker compose up -d --force-recreate
"$HOME/server/scripts/verify.sh"
```

If live data is incompatible or damaged, restore a validated portable collection snapshot into a clean collection.


## Related documentation

- [M04 milestone record](../milestones/M04-Qdrant.md)
- [Installing Qdrant](../runbooks/Installing-Qdrant.md)
- [Backing up Qdrant](../runbooks/Backing-Up-Qdrant.md)
- [Restoring Qdrant](../runbooks/Restoring-Qdrant.md)
- [Troubleshooting Qdrant](../runbooks/Troubleshooting-Qdrant.md)
