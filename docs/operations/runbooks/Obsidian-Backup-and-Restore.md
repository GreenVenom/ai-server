---
title: Obsidian Backup and Restore Runbook
document: Runbook
status: Active
created: 2026-07-18
updated: 2026-07-18
platform_version: v0.5.0
owner: GreenVenom
---

# Obsidian Backup and Restore Runbook

## Purpose

Back up and recover the reproducible operational state for the M05 Obsidian integration.

## Prerequisites

- Access to the Mac mini account that owns the Obsidian LaunchAgent.
- A healthy authoritative private Git repository or a verified Qdrant snapshot.
- Sufficient local storage for a new archive and, before a destructive restore, a fresh snapshot of the current collection.

## Backup scope

The authoritative vault is protected by its private Git repository. The server backup contains reproducible operational state:

- Obsidian configuration;
- vault registration;
- ingestion service source;
- OpenClaw plugin source and manifests;
- operational scripts;
- LaunchAgent definition;
- indexing manifest;
- source commit state;
- scheduled-job state;
- Qdrant collection snapshot;
- backup metadata and SHA-256 checksum.

The server mirror, Python virtual environment, `node_modules`, and build outputs are intentionally excluded.

## Create a backup

```bash
~/server/scripts/backup-obsidian.sh
```

Backups are written under:

```text
~/server/backups/obsidian/obsidian-<timestamp>.tar.gz
```

## Validate an archive

```bash
archive="$(find ~/server/backups/obsidian -name 'obsidian-*.tar.gz' | sort | tail -1)"
tar -tzf "$archive"
```

Extract to a temporary directory and compare the archived snapshot checksum to `backup-metadata.json` before restoration.

## Restore sequence

1. Stop the scheduled LaunchAgent.
2. Preserve the current state and collection before changing anything.
3. Extract the operational archive.
4. Restore configuration, service source, scripts, and LaunchAgent files to their documented paths.
5. Recreate the Python virtual environment from `requirements.lock`.
6. Rebuild the OpenClaw plugin with `npm ci` and `npm run build`.
7. Restore or re-clone the authoritative Git checkout.
8. Recreate the Markdown mirror.
9. Restore the Qdrant snapshot or perform a full index.
10. Reload the LaunchAgent.
11. Run `check-obsidian.sh`, `health.sh`, and retrieval tests.

## Restore preference

Prefer rebuilding the mirror and index from the authoritative Git repository when practical. Use the Qdrant snapshot when faster recovery or preservation of an exact index state is required.

## Snapshot restore caution

Qdrant snapshot restoration is collection-specific and potentially destructive. Take a fresh snapshot of the current collection before replacing it.

## Troubleshooting

- If archive validation fails, do not restore it; create a new backup from the current operational state or recover from the authoritative Git repository.
- If a restored collection does not reconcile with its manifest, rebuild the mirror and run a full index before enabling scheduled incremental runs.

## Related documentation

- [Obsidian operations runbook](Obsidian-Operations.md)
- [M05 milestone record](../milestones/M05-Obsidian-Integration.md)
