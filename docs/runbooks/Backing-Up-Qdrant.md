---
title: Backing Up Qdrant
document: Runbook
status: Active
created: 2026-07-17
updated: 2026-07-17
platform_version: v0.4.0
owner: Personal AI Platform maintainers
---

# Backing Up Qdrant

## Purpose

Create and retain validated Qdrant recovery artifacts.

## Prerequisites

- Qdrant and Ollama are healthy.
- The backup directories are writable by the `openclaw` user.

## Backup layers

### Internal collection snapshot

A native snapshot stored inside Qdrant's snapshot storage. Useful for short-term operations, but not independent of the Qdrant storage boundary.

### Portable host snapshot

A downloaded collection snapshot stored under:

```text
~/server/backups/qdrant/snapshots
```

### Manifest

A JSON record stored under:

```text
~/server/backups/qdrant/manifests
```

The manifest records the collection, schema, embedding model, dimension, point count, Qdrant version, filename, timestamp, size, and checksum.

## Procedure

Use the automated backup and restore test:

```bash
"$HOME/server/scripts/tests/qdrant-backup-restore-test.sh"
```

The test:

1. checks Qdrant and Ollama;
2. reads source collection metadata;
3. creates a native snapshot;
4. downloads the snapshot;
5. checks byte size;
6. checks SHA-256;
7. creates a JSON manifest;
8. restores into a disposable collection;
9. verifies schema, points, payload, vector, and semantic ranking;
10. deletes the disposable restore collection;
11. deletes its internal snapshot by default;
12. retains the portable snapshot and manifest.

## Retain the Internal Snapshot

```bash
DELETE_INTERNAL_SNAPSHOT=false   "$HOME/server/scripts/tests/qdrant-backup-restore-test.sh"
```

Use only for troubleshooting or a deliberate short-term recovery point.

## Integrity Check

```bash
shasum -a 256   "$HOME/server/backups/qdrant/snapshots/<snapshot>.snapshot"
```

Compare the result to the manifest before restoration.

## Retention

```text
Internal snapshots  7 days
Portable backups    30 days
```

Preview cleanup:

```bash
"$HOME/server/scripts/maintenance/qdrant-snapshot-cleanup.sh"
```

Apply cleanup:

```bash
DRY_RUN=false   "$HOME/server/scripts/maintenance/qdrant-snapshot-cleanup.sh"
```

Portable snapshots and manifests are deleted as a pair. A snapshot without a manifest is retained unless `FORCE_ORPHAN_DELETE=true` is explicitly supplied.

## Git Policy

Do not commit:

- `.snapshot` files;
- snapshot manifests containing runtime details;
- indexed source content;
- credentials or future API keys.


## Validation

A successful backup passes the automated backup-and-restore test, including checksum, manifest, clean restore, and semantic-ranking verification.

## Troubleshooting

If snapshot creation, checksum validation, or restore validation fails, follow [Troubleshooting Qdrant](Troubleshooting-Qdrant.md).

## Related documentation

- [Restoring Qdrant](Restoring-Qdrant.md)
- [ADR-0013](../decisions/ADR-0013-Qdrant-Snapshot-Retention-and-Cleanup.md)
