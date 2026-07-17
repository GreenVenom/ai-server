---
title: ADR-0013 - Standardize Qdrant Snapshot Retention and Cleanup
document: ADR
status: Accepted
created: 2026-07-17
updated: 2026-07-17
platform_version: v0.3.0
owner: Personal AI Platform maintainers
decision_id: ADR-0013
supersedes:
superseded_by:
---

# ADR-0013 - Standardize Qdrant Snapshot Retention and Cleanup

- **Status:** Accepted
- **Date:** 2026-07-17
- **Decision Owners:** Personal AI Platform maintainers
- **Milestone:** M04 — Qdrant Vector Database

## Context

M04.6 established and automated collection-level backup and restore for Qdrant.

The validated recovery workflow:

1. creates a native Qdrant collection snapshot;
2. downloads a portable copy to the host;
3. verifies its byte size;
4. verifies its SHA-256 checksum;
5. creates a JSON manifest;
6. restores the snapshot into a disposable collection;
7. verifies collection schema and point count;
8. verifies payload and vector recovery;
9. repeats the semantic query;
10. removes the disposable restore collection.

This workflow creates two snapshot layers:

```text
Internal Qdrant snapshot
    managed within Qdrant storage

Portable host snapshot
    ~/server/backups/qdrant/snapshots

Portable manifest
    ~/server/backups/qdrant/manifests
```

Without retention rules, repeated validation and future scheduled backups would consume storage indefinitely.

Cleanup must not remove the only portable recovery copy, separate a snapshot from its manifest, or silently delete orphaned artifacts.

## Decision

The Personal AI Platform will manage internal Qdrant snapshots and portable host backups as separate retention classes.

## Internal Snapshot Policy

Internal Qdrant snapshots are short-lived operational artifacts.

Default retention:

```text
7 days
```

The automated backup-and-restore test will delete the internal snapshot it creates after:

- the portable snapshot has downloaded successfully;
- size verification has passed;
- SHA-256 verification has passed;
- manifest creation has passed;
- restore validation has passed;
- semantic search validation has passed.

The test may retain its internal snapshot when explicitly invoked with:

```text
DELETE_INTERNAL_SNAPSHOT=false
```

This override is intended for troubleshooting.

## Portable Host Backup Policy

Portable host snapshots and their manifests are the authoritative collection-level recovery artifacts produced by M04.

Default retention:

```text
30 days
```

Portable snapshot path:

```text
~/server/backups/qdrant/snapshots/*.snapshot
```

Manifest path:

```text
~/server/backups/qdrant/manifests/*.snapshot.json
```

A snapshot and its corresponding manifest form one backup unit and will be deleted together.

## Orphan Policy

A portable snapshot with no matching manifest will not be deleted automatically.

It will be reported as an orphan and retained.

Expired orphan snapshots may be deleted only through the explicit override:

```text
FORCE_ORPHAN_DELETE=true
```

Unrelated files outside the expected snapshot and manifest filename patterns will be ignored.

## Cleanup Safety

The maintenance cleanup script will run in dry-run mode by default:

```text
DRY_RUN=true
```

Deletion requires explicit activation:

```text
DRY_RUN=false
```

Internal and host cleanup can be independently enabled or disabled:

```text
CLEAN_INTERNAL
CLEAN_HOST
```

Retention values can be overridden without editing the script:

```text
INTERNAL_RETENTION_DAYS
HOST_RETENTION_DAYS
```

The cleanup report will show:

- internal snapshots selected;
- internal snapshots retained;
- internal reclaimable bytes;
- host backup pairs selected;
- host backup pairs retained;
- orphan snapshot count;
- host reclaimable bytes;
- whether the run was a dry run.

## Rationale

Separate retention policies were selected because internal and portable snapshots serve different purposes.

Internal snapshots:

- reside within the same Qdrant storage boundary;
- are convenient for short-term operational recovery;
- should not be treated as independent disaster-recovery copies;
- can accumulate through manual or interrupted operations.

Portable host backups:

- exist outside the Qdrant live data boundary;
- include integrity metadata;
- can be uploaded into a clean collection;
- are the verified recovery artifacts produced by M04.6;
- require longer retention.

Dry-run-by-default and paired deletion reduce the risk of accidental backup loss.

## Alternatives Considered

### 1. Retain all snapshots indefinitely

Rejected.

Unbounded retention would consume disk space and provide no defined operational lifecycle.

### 2. Delete all internal snapshots immediately

Rejected as a universal policy.

The automated test should delete its own internal snapshot after successful recovery validation, but manually created snapshots may still be useful for short-term troubleshooting.

### 3. Apply one retention period to both layers

Rejected.

Internal snapshots and portable backups have different independence and recovery value.

### 4. Delete portable snapshots without checking manifests

Rejected.

A missing manifest may indicate an interrupted workflow or integrity problem. Automatic deletion would remove evidence and potentially the only recovery artifact.

### 5. Delete manifests and snapshots independently

Rejected.

The manifest contains the checksum, schema, model, dimension, version, point count, and timestamps needed to validate the snapshot.

### 6. Make deletion the default behavior

Rejected.

Maintenance cleanup should be observable and safe before it becomes destructive.

### 7. Store snapshots in Git

Rejected.

Snapshot files are binary runtime backup artifacts and may contain indexed content. They do not belong in source control.

## Consequences

### Positive

- Snapshot growth is bounded.
- Portable recovery copies receive longer retention.
- Snapshot and manifest integrity is preserved.
- Orphans are visible rather than silently removed.
- Cleanup can be previewed safely.
- Internal and host policies can evolve independently.
- M08 can build on a documented baseline.

### Negative

- The cleanup process must be run or scheduled.
- A 30-day host policy does not protect against failures discovered after the retention window.
- Portable backups remain on the same physical Mac unless copied elsewhere.
- Orphan files require operator review or explicit forced cleanup.
- Retention configuration adds operational parameters.

### Operational

The maintenance script is:

```text
~/server/scripts/maintenance/qdrant-snapshot-cleanup.sh
```

Safe preview:

```bash
~/server/scripts/maintenance/qdrant-snapshot-cleanup.sh
```

Apply the default policy:

```bash
DRY_RUN=false \
  ~/server/scripts/maintenance/qdrant-snapshot-cleanup.sh
```

Override host retention:

```bash
HOST_RETENTION_DAYS=60 \
DRY_RUN=false \
  ~/server/scripts/maintenance/qdrant-snapshot-cleanup.sh
```

Clean only internal snapshots:

```bash
CLEAN_INTERNAL=true \
CLEAN_HOST=false \
DRY_RUN=false \
  ~/server/scripts/maintenance/qdrant-snapshot-cleanup.sh
```

Delete eligible orphan snapshots explicitly:

```bash
FORCE_ORPHAN_DELETE=true \
DRY_RUN=false \
  ~/server/scripts/maintenance/qdrant-snapshot-cleanup.sh
```

A periodic cadence may be introduced after repeated dry-run and destructive-run validation. A weekly cleanup cadence is appropriate for the current retention values.

## Validation

The M04.6 backup-and-restore automation passed:

```text
Passed  29
Failed  0
```

It verified:

- snapshot creation;
- portable download;
- size matching;
- SHA-256 matching;
- valid manifest creation;
- clean restore;
- schema equality;
- point-count equality;
- payload recovery;
- vector recovery;
- semantic-search recovery;
- disposable restore cleanup.

The snapshot cleanup script has also completed a successful dry run using the accepted policy.

## Revisit Conditions

Revisit this decision if:

- M08 defines a platform-wide backup standard;
- backups are copied to external or off-site storage;
- production collections require longer retention;
- recovery-point or recovery-time objectives are defined;
- available disk space changes materially;
- encryption-at-rest requirements apply to portable snapshots;
- multiple collections require different policies;
- scheduled automation introduces alerting or failure-handling requirements.

## Related documentation

- [Documentation map](../README.md)
