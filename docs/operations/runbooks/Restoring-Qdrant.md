---
title: Restoring Qdrant
document: Runbook
status: Active
created: 2026-07-17
updated: 2026-07-17
platform_version: v0.4.0
owner: GreenVenom
---

# Restoring Qdrant

## Purpose

Restore into a separate collection first. Do not overwrite a healthy source collection during validation.

## Prerequisites

- Qdrant is healthy.
- Snapshot and matching manifest are available.
- SHA-256 matches the manifest.
- Target collection name does not already contain required production data.
- Qdrant version compatibility has been reviewed.

## Validate the Artifact

```bash
shasum -a 256   "$HOME/server/backups/qdrant/snapshots/<snapshot>.snapshot"

python3 -m json.tool   "$HOME/server/backups/qdrant/manifests/<snapshot>.snapshot.json"
```

## Procedure

The automated path is preferred:

```bash
"$HOME/server/scripts/tests/qdrant-backup-restore-test.sh"
```

For a manual restore, upload or recover the snapshot through the Qdrant snapshot API into a new collection.

Recommended target pattern:

```text
<source>_restore_v<schema>
```

Example:

```text
validation_m04_restore_v1
```

## Validation

Confirm:

```text
collection status  green
point count        matches manifest
vector name        text-dense
dimension          768
distance           Cosine
payloads           present
vectors            present
semantic ranking   expected
```

Run a direct collection inspection, direct point retrieval, and the standard semantic query.

## Cutover

M04 does not define production alias cutover. For future production collections:

1. restore into a separate collection;
2. validate completely;
3. pause writers;
4. switch a collection alias or client configuration;
5. retain the prior collection for a defined rollback period;
6. resume writers;
7. monitor retrieval.

## Cleanup

Delete only the disposable restore collection after validation. Retain the portable snapshot and manifest according to ADR-0013.


## Troubleshooting

If artifact validation or collection recovery fails, follow [Troubleshooting Qdrant](Troubleshooting-Qdrant.md).

## Related documentation

- [Backing up Qdrant](Backing-Up-Qdrant.md)
- [Qdrant operations](../Qdrant-Operations.md)
