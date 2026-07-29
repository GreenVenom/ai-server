---
title: ADR-0023 Encrypted Google Drive Off-Host Backups
document: ADR
status: Accepted
created: 2026-07-28
updated: 2026-07-28
platform_version: v0.8.0
owner: GreenVenom
decision_id: ADR-0023
supersedes: null
superseded_by: null
---

# ADR-0023 Encrypted Google Drive Off-Host Backups

- **Status:** Accepted
- **Date:** 2026-07-28
- **Decision makers:** Personal AI Server project maintainers
- **Related:** ADR-0013, ADR-0022, M08 Backup and Disaster Recovery Deployment Plan

## Context

M08 requires an encrypted, durable, off-host destination for the personal AI
server's recoverable platform state. The server already has a verified,
application-consistent snapshot of the live `obsidian_chunks_v2` Qdrant
collection, including a SHA-256 checksum and a recovery manifest. The project
must now retain off-host copies without making the Mac mini a source of truth
for the user's Obsidian notes.

The system is local-first and cost-sensitive. A dedicated Google account has
been created for backups. Google Drive provides a no-cost off-host location
within the account's shared storage quota, but it must not receive readable
backup contents, readable filenames, or encryption material. The design must
also prevent unbounded retention from silently consuming the free quota.

The V1 Obsidian index and its original manifest are already protected by
ADR-0022: they remain an unmodified, known-good rollback target through at
least 2026-08-26.

## Decision

1. Use the dedicated Google Drive account as the off-host destination for M08
   backup copies.
2. Use an `rclone crypt` remote over the Google Drive remote. Backup archives,
   Qdrant snapshots, manifests, and their names are encrypted locally before
   upload. Google Drive stores ciphertext only.
3. Store the `rclone crypt` password and salt outside the backup destination,
   repository, runtime configuration, logs, and backup archives. Their
   recovery material is maintained through a separately controlled process.
4. Back up only allow-listed recovery artifacts:
   - application-consistent Qdrant snapshots and their SHA-256 manifests;
   - the active V2 index manifest and selected non-secret runtime
     configuration, service definitions, and scheduler definitions needed to
     redeploy and validate the service; and
   - recovery metadata required to validate checksums and restore into a
     replacement collection.

   Do not back up the server-side Obsidian mirror, authoritative Obsidian
   notes, secrets, private keys, virtual environments, `node_modules`, logs,
   Docker images, or live Docker volumes as broad archive inputs.
5. Apply the following bounded retention policy to successful off-host backup
   sets:

   | Tier | Retention | Selection |
   | --- | --- | --- |
   | Daily | 7 copies | Most recent successful backup for each UTC day |
   | Weekly | 4 copies | Most recent successful backup for each UTC week |
   | Monthly | 6 copies | Most recent successful backup for each UTC month |
   | Rollback | At least 30 days | Preserve the ADR-0022 V1 rollback artifacts unchanged through at least 2026-08-26 |

   A backup set retained by more than one tier is stored once and counted by
   every applicable tier. Retention cleanup occurs only after the new backup
   has uploaded, its checksum has been verified, and its manifest is present.
6. Before every upload, the backup job checks available destination capacity
   against a conservative configured threshold. If the threshold is not met,
   the job fails closed: it does not delete the newest valid local or off-host
   backup, and it reports the failure through M08 monitoring.
7. The backup job is non-interactive. OAuth authorization is completed during
   controlled setup, and the resulting credentials are readable only by the
   `openclaw` account. Logs must not print credentials, passphrases, archive
   contents, or plaintext remote paths.

## Consequences

### Positive

- Provides automated, encrypted, geographically separate recovery copies with
  no paid storage plan required for the intended bounded backup set.
- Keeps encryption client-side: the storage provider cannot read backup data
  or meaningful backup filenames.
- Preserves clear recovery provenance through snapshots, manifests, and
  SHA-256 validation.
- Limits cost and quota risk through bounded retention and a capacity gate.
- Maintains the project's established boundary that the primary workstation's
  private Git repository, not the server mirror, remains authoritative for
  Obsidian notes.

### Trade-offs

- Recovery depends on both the Google account and separately retained `rclone
  crypt` recovery material; loss of either can make encrypted backups
  unrecoverable.
- Google Drive availability and its shared free storage quota are external
  dependencies. A full account or unavailable service blocks new off-host
  copies until remediated.
- `rclone` OAuth credentials and encryption configuration require careful
  least-privilege storage and periodic recovery testing.
- The free tier is appropriate only while capacity checks show the retained
  backup set fits comfortably within the dedicated account's available quota.
  Growth beyond that threshold requires a separately recorded storage
  decision.

## Operational Requirements

The M08 backup implementation and monitoring must:

1. create new local backup artifacts before any off-host retention cleanup;
2. verify each archive or snapshot checksum before declaring an upload
   successful;
3. upload through the encrypted `rclone crypt` remote only, never the
   plaintext Google Drive remote;
4. retain the local checksum and manifest necessary to verify a downloaded
   restore candidate;
5. expose the timestamp and outcome of the last successful backup without
   exposing sensitive data; and
6. perform a restore drill into separate Qdrant collection names before M08
   closeout.

## Acceptance Criteria

This decision is implemented when all of the following have been demonstrated:

| Check | Expected result |
| --- | --- |
| Destination | Dedicated Google Drive account is authorized for `openclaw` backup use |
| Encryption | A test upload shows encrypted file content and encrypted filenames in Drive |
| Scope | Archive manifest contains only the allow-listed recovery artifacts |
| Integrity | Uploaded backup can be downloaded and passes its recorded SHA-256 checksum |
| Retention | Daily, weekly, monthly, and V1 rollback rules are enforced without deleting a newest valid copy |
| Capacity | Pre-upload threshold is checked and a simulated capacity failure fails closed |
| Recovery | Restore drill validates a replacement Qdrant collection and manifest reconciliation |

## Rollback

If Google Drive or the encrypted remote cannot satisfy the capacity,
availability, encryption, or restore-validation requirements, disable the
automated upload job while retaining existing validated local artifacts. Do
not delete existing off-host copies. Select and record a replacement encrypted
off-host destination in a new ADR before resuming automated off-host backups.

## Related documentation

- [M08 milestone record](../operations/milestones/M08-Backup-and-Disaster-Recovery.md)
- [Backup and recovery runbook](../operations/Backup-and-Recovery-Runbook.md)
- [v0.8.0 release notes](../releases/v0.8.0.md)
