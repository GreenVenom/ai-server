---
title: M08 Backup and Disaster Recovery
document: Milestone
status: Complete
created: 2026-07-28
updated: 2026-07-28
platform_version: v0.8.0
owner: GreenVenom
---

# M08 Backup and Disaster Recovery

## Objective

Establish a repeatable, evidence-based recovery path for recoverable platform state without making the Mac mini a source of truth for the user's Obsidian notes.

## Scope

Included:

- Encrypted off-host backup copies of the active V2 Qdrant index, integrity metadata, and allow-listed non-secret runtime configuration.
- Automated daily execution, upload verification, bounded retention, and fail-closed capacity handling.
- A non-production restore drill and documented routine recovery and full-host rebuild procedures.

Excluded:

- The authoritative Obsidian vault and server-side vault mirror.
- Secrets, private keys, rclone configuration, logs, Docker images and volumes, virtual environments, and build outputs.

## Deliverables

- [ADR-0023](../../decisions/ADR-0023-Encrypted-Google-Drive-Off-Host-Backups.md) defining encryption, scope, retention, capacity, and recovery controls.
- Repository-managed off-host backup script and LaunchAgent schedule.
- [Backup and recovery runbook](../Backup-and-Recovery-Runbook.md) for normal operation, controlled restore, and full-host rebuild.
- [v0.8.0 release notes](../../releases/v0.8.0.md) recording acceptance evidence.

## Validation

The M08 restore drill downloaded encrypted set `2026-07-29T013825Z`, validated its snapshot and runtime archive against SHA-256 values in `backup-manifest.json`, and restored the snapshot into separate collection `m08_restore_20260729t013825z`.

The restored collection was green with the `text-dense` vector, 768 dimensions, and Cosine distance. It contained 265 points, matching the production `obsidian_chunks_v2` collection, and passed V2 manifest reconciliation. Production data was not modified.

## Exit Criteria

M08 is complete because encrypted off-host backups, automated execution, post-upload verification, controlled retention, non-production restore validation, and recovery documentation are in place. Ongoing retention and recovery-control exercises are tracked in the runbook and release notes.

## Related documentation

- [Roadmap](../../../ROADMAP.md)
- [ADR-0023](../../decisions/ADR-0023-Encrypted-Google-Drive-Off-Host-Backups.md)
- [Backup and recovery runbook](../Backup-and-Recovery-Runbook.md)
- [v0.8.0 release notes](../../releases/v0.8.0.md)
