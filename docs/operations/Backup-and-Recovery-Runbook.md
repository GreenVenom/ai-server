---
title: Backup and Recovery Runbook
document: Runbook
status: Active
created: 2026-07-28
updated: 2026-07-28
platform_version: v0.8.0
owner: GreenVenom
---

# Backup and Recovery Runbook

- **Applies to:** M08 Backup and Disaster Recovery
- **Runtime account:** `openclaw`
- **Live collection:** `obsidian_chunks_v2`
- **Backup decision:** ADR-0023
- **Last validated restore drill:** 2026-07-29

## Purpose

This runbook restores the personal AI server's recoverable runtime state. It does not restore the authoritative Obsidian vault. The workstation's private Git repository remains the authority for note content; server-side vault mirrors and note content are intentionally excluded from M08 backup sets.

M08 backup sets contain only:

- an application-consistent Qdrant snapshot for `obsidian_chunks_v2`;
- `backup-manifest.json` with SHA-256 checksums and vector contract;
- the active V2 index manifest and source-commit marker; and
- the allow-listed non-secret Qdrant, backup-script, and LaunchAgent configuration.

They never contain secrets, private keys, rclone configuration, logs, Docker volumes/images, virtual environments, or the Obsidian mirror.

## Prerequisites

- Access to the `openclaw` runtime account, the protected rclone configuration, and the encrypted off-host backup remote.
- A selected, verified backup set and a new non-production collection name for restore testing.

## Procedure

### Normal operation

The `openclaw` LaunchAgent runs daily at 03:30 local time:

```text
com.personal-ai.offhost-backup
└── /Users/openclaw/server/scripts/backup-offhost.sh
```

Review the most recent state without exposing credentials:

```bash
python3 -m json.tool "$HOME/server/data/backup/offhost-backup-state.json"
tail -n 80 "$HOME/server/logs/backup/offhost-backup.launchd.log"
launchctl print "gui/$(id -u)/com.personal-ai.offhost-backup" | sed -n '1,65p'
```

The expected successful state is `"status": "success"` with `"exit_code": 0`. A backup failure must be investigated before assuming a current off-host recovery point exists.

### Restore a backup set to a non-production collection

Use this procedure for recovery testing or to inspect a backup candidate. It never overwrites `obsidian_chunks_v2`.

1. Select a verified set under `gdrive_backup_crypt:sets/` and choose a new restore collection name.
2. Download the encrypted set using the protected rclone configuration password from `$HOME/server/config/backup/rclone.env`. Do not print or copy its value.
3. Verify the downloaded snapshot and runtime archive against the SHA-256 values in `backup-manifest.json`.
4. Confirm that the target collection does not already exist.
5. Upload the snapshot to the target collection using Qdrant's snapshot-upload endpoint.
6. Verify that the replacement collection is green and its `text-dense` vector is 768 dimensions with Cosine distance.
7. Compare exact point counts and reconcile the restored index against its V2 manifest before any promotion decision.

The validated M08 drill used encrypted set `2026-07-29T013825Z`, restored it to `m08_restore_20260729t013825z`, and confirmed 265 source points and 265 restored points.

### Promote a recovered collection

Do not promote a collection merely because snapshot upload succeeded. First validate collection health, the vector contract, exact point count, index-manifest reconciliation, the Obsidian retrieval MCP check, and the normal platform health checks. Promotion must be a deliberate maintenance change with a rollback plan; preserve the existing production collection until the replacement path is validated.

### Full-host rebuild

1. Rebuild the Mac mini baseline and sign in as `openclaw`.
2. Clone the pinned private `ai-server` repository; it is the authority for source, service definitions, and documentation.
3. Install the pinned runtime dependencies and deploy the Qdrant Docker configuration loopback-only.
4. Recover rclone OAuth access and the rclone-configuration password through their separately controlled recovery material. Do not retrieve them from the Git repository, backup archive, logs, or this runbook.
5. Create `$HOME/server/config/backup/rclone.env` with mode `0600`, owned by `openclaw`, and validate it non-interactively with `rclone listremotes` before enabling automation.
6. Download the selected encrypted backup set, verify its checksums, and restore the Qdrant snapshot to a replacement collection.
7. Restore only the archive's allow-listed non-secret runtime configuration. Review ownership and restrictive permissions before loading the LaunchAgent.
8. Deploy the repository's backup script and LaunchAgent, validate syntax, then test the job through `launchctl`.
9. Complete the production validation suite: platform status/health, V2 manifest reconciliation, retrieval MCP health, and an intentional collection-promotion verification.

## Security boundary

The following are outside M08 backups and Git and must be recovered independently:

- rclone configuration password, crypt password, and crypt salt;
- rclone OAuth credentials;
- SSH private keys and any API/service credentials; and
- any secret files below `$HOME/server/config`.

Keep recovery material in its separately controlled location. Do not add it to an archive, issue, commit, command history, or operational log.

## Validation

A successful restore validates the downloaded SHA-256 values, archive scope, replacement-collection health, `text-dense` vector contract, exact point count, and V2 manifest reconciliation. Production data must remain unchanged.

## Recurring validation

| Control | Frequency | Required evidence |
| --- | --- | --- |
| Review last backup state and LaunchAgent health | Weekly | Successful state record and no unresolved backup failure |
| Confirm retention selection | Monthly, after more than seven daily runs | The encrypted remote keeps the required 7 daily / 4 weekly / 6 monthly recovery points and removes only eligible older sets |
| Capacity fail-closed exercise | Quarterly and after quota-policy changes | A safely simulated insufficient-capacity condition causes no upload or retention cleanup and reports failure |
| Non-production restore drill | Quarterly and before material Qdrant/backup changes | Downloaded checksums, green replacement collection, contract validation, and exact manifest/point reconciliation |
| Full-host rebuild rehearsal | Annually or after architecture changes | Rebuild record demonstrating repository deployment, independent secret recovery, restore, and platform verification |

The ADR-0022 V1 rollback collection and original manifest remain unchanged through at least 2026-08-26. That retention boundary is independent of routine M08 off-host cleanup.

## Troubleshooting

If the latest backup state is not successful, do not assume a current recovery point exists. Investigate the LaunchAgent output, remote capacity, encryption configuration availability, and recorded checksum failures before retrying. Do not disable encryption, upload through the plaintext remote, or overwrite the production collection as a troubleshooting shortcut.

## Related documentation

- [M08 milestone record](milestones/M08-Backup-and-Disaster-Recovery.md)
- [ADR-0023](../decisions/ADR-0023-Encrypted-Google-Drive-Off-Host-Backups.md)
- [v0.8.0 release notes](../releases/v0.8.0.md)

