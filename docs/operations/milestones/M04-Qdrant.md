---
title: M04 - Qdrant Vector Database
document: Milestone
status: Complete
created: 2026-07-17
updated: 2026-07-17
platform_version: v0.4.0
owner: GreenVenom
---

# M04 - Qdrant Vector Database

- **Status:** Complete
- **Completion date:** 2026-07-17
- **Predecessor:** M03 — OpenClaw Platform
- **Successor:** M05 — Obsidian Integration

## Objective

Deploy and operationalize Qdrant as a secure, persistent, tested vector-storage service for the Personal AI Platform.

## Outcome

M04 delivered a version-pinned, loopback-only Qdrant deployment with durable storage, a validated Ollama embedding contract, deterministic collection conventions, tested semantic retrieval, snapshot recovery, retention tooling, lifecycle resilience, controlled failure diagnostics, and integration into the platform status, health, and verification scripts.

## Final Production Contract

```text
Qdrant version       1.18.2
Image                qdrant/qdrant:v1.18.2
Container            personal-ai-qdrant
Restart policy       always
REST                 127.0.0.1:6333
gRPC                 127.0.0.1:6334
Live data            personal-ai-qdrant-storage
Storage target       /qdrant/storage
Snapshot target      /qdrant/snapshots
Portable snapshots   ~/server/backups/qdrant/snapshots
Manifests            ~/server/backups/qdrant/manifests
Telemetry            disabled
```

## Embedding and Retrieval Contract

```text
Embedding model       nomic-embed-text:latest
Embedding dimension   768
Named vector          text-dense
Distance metric       Cosine
Validation collection m04_validation
Point count           5
Collection status     green
```

Standard semantic ranking:

```text
1. OpenClaw Gateway
2. Ollama Runtime
3. Benchmark Framework
4. Docker Startup
5. Garden Maintenance
```

The control passage consistently ranked last.

## Data Conventions

```text
Collection pattern     <domain>_<purpose>_v<schema-version>
Point ID               deterministic UUIDv5
Point identity input   source_type|source_id|chunk_id
Document identity      source_type|source_id
UUID namespace         b83a8b73-03e0-5f87-a8fb-3f8996cf6f21
Content hash           SHA-256
Timestamp format       UTC RFC 3339
Payload schema         version 1
```

Required payload fields:

```text
schema_version
source_type
source_id
document_id
chunk_id
title
text
content_hash
source_modified_at
indexed_at
embedding_model
embedding_dimension
```

## Implementation Phases

### M04.1 — Requirements and Deployment Decision

Completed:

- verified Docker and Compose;
- selected Qdrant 1.18.2;
- defined local-only ports;
- established Docker Desktop login dependency;
- selected single-node Compose deployment.

### M04.2 — Container Deployment

Completed:

- version-pinned image;
- loopback REST and gRPC;
- healthy container;
- telemetry disabled;
- Docker named volume;
- host snapshot bind;
- filesystem warning resolved.

### M04.3 — Operational Integration

Completed:

- Qdrant added to `status.sh`;
- Qdrant added to `health.sh`;
- Qdrant added to `verify.sh`;
- service, API, version, image, restart, mount, network, collection, and vector checks implemented.

### M04.4 — Embedding Contract Validation

Completed:

- measured 768-dimensional embeddings;
- validated stable dimensions;
- created named-vector collection;
- inserted five controlled passages;
- validated direct retrieval;
- validated semantic ranking;
- validated payload filtering.

### M04.5 — Collection and Metadata Conventions

Completed:

- versioned collection naming;
- deterministic UUIDv5 points and documents;
- required payload schema;
- SHA-256 content hashes;
- UTC RFC 3339 timestamps;
- automated smoke test passed 20/20.

### M04.6 — Backup and Restore Validation

Completed:

- native collection snapshot;
- portable download;
- byte-size validation;
- SHA-256 validation;
- JSON manifest;
- clean restore collection;
- schema, points, payload, vectors, and ranking verification;
- automated backup/restore test passed 29/29;
- retention and cleanup tooling implemented.

### M04.7 — Restart and Failure Testing

Completed:

```text
Baseline persistence           PASS
Container restart              PASS
Container recreation           PASS
Docker Desktop restart         PASS
Account logout/login           PASS
Machine reboot                 PASS
Stopped-container diagnostic   PASS
Missing-collection diagnostic  PASS
Wrong expected dimension       PASS
Actual invalid vector rejected PASS
```

Testing revealed that `restart: unless-stopped` did not restore Qdrant after Docker Desktop restart. The policy was changed to `restart: always`, after which Docker restart, logout/login, and reboot recovery passed.

### M04.8 — Documentation and Release Closeout

Completed documentation package:

- ADR-0011 through ADR-0013;
- Qdrant architecture;
- retrieval boundary;
- data and collection conventions;
- operations guide;
- installation runbook;
- backup runbook;
- restore runbook;
- troubleshooting runbook;
- milestone record;
- release notes;
- README, ROADMAP, and VERSION update guidance.

## Validation Evidence

Final platform outputs:

```text
status.sh
  Qdrant running and healthy
  REST ready
  gRPC open
  Qdrant 1.18.2
  m04_validation green, 5 points

health.sh
  45 passed
  0 warnings
  0 failed

verify.sh
  44 passed
  0 warnings
  0 failed
```

Dedicated tests:

```text
qdrant-test.sh                    20 passed, 0 failed
qdrant-backup-restore-test.sh     29 passed, 0 failed
qdrant-persistence-check.sh       12 passed, 0 failed
```

## Architecture Decisions

- ADR-0011 — Deploy Qdrant as a Docker Compose Service
- ADR-0012 — Standardize Qdrant Collection, Vector, and Embedding Metadata
- ADR-0013 — Standardize Qdrant Snapshot Retention and Cleanup

## Acceptance Criteria

### Deployment

- [x] Qdrant version explicitly pinned.
- [x] Docker Compose deployment operational.
- [x] Automatic restart policy validated.
- [x] Runs under the `openclaw` Docker Desktop environment.

### Security

- [x] REST bound only to loopback.
- [x] gRPC bound only to loopback.
- [x] No direct LAN or Tailscale publication.
- [x] Secrets and snapshot Git policy documented.
- [x] Future authentication boundary documented.

### Persistence

- [x] Live data stored in named volume.
- [x] Data survives container restart.
- [x] Data survives container recreation.
- [x] Data survives Docker Desktop restart.
- [x] Data survives logout/login.
- [x] Data survives machine reboot.

### Embeddings and Retrieval

- [x] `nomic-embed-text` validated.
- [x] Dimension measured and documented.
- [x] Named-vector collection created.
- [x] Points and payloads inserted.
- [x] Semantic search credible.
- [x] Payload filtering works.
- [x] Direct point retrieval works.
- [x] Validation workflow automated.

### Operations

- [x] `status.sh` reports Qdrant.
- [x] `health.sh` validates Qdrant.
- [x] `verify.sh` enforces Qdrant production invariants.
- [x] Logs and lifecycle commands documented.
- [x] Controlled failures produce actionable diagnostics.

### Recovery

- [x] Collection snapshot created.
- [x] Manifest and checksum recorded.
- [x] Clean restore completed.
- [x] Restored schema, payloads, vectors, and search validated.
- [x] Snapshot retention and cleanup implemented.

### Documentation

- [x] Architecture documented.
- [x] Operations documented.
- [x] Backup, restore, and troubleshooting documented.
- [x] ADRs completed.
- [x] Release package prepared.
- [x] M04 milestone ready to commit and tag.

## Deviations From the Initial Plan

- Live data uses a Docker named volume rather than `~/server/data/qdrant`.
- Restart policy is `always`, not `unless-stopped`.
- The retained validation collection name is `m04_validation`.
- API authentication remains deferred because Qdrant is loopback-only.
- A separate provider-neutral vector-store abstraction was not introduced; it is unnecessary until a second provider exists.

## Known Constraints

- Docker-backed services require `openclaw` user login.
- Qdrant does not run before Docker Desktop starts.
- Portable snapshots currently reside on the same physical Mac.
- M08 must introduce broader off-host disaster recovery.
- No production Obsidian content is indexed yet.
- No OpenClaw retrieval client is connected yet.

## Handoff to M05

M05 can now focus on:

- Obsidian vault discovery;
- Markdown parsing;
- chunking;
- metadata extraction;
- deterministic indexing;
- incremental updates;
- source deletion;
- retrieval behavior.

M05 should build against ADR-0012 and should not redesign the established vector or payload contract without a new ADR.


## Exit criteria

M04 is complete because its deployment, persistence, retrieval, recovery, security, and operations acceptance criteria have passed.

## Related documentation

- [v0.4.0 release notes](../../releases/v0.4.0.md)
- [Qdrant operations](../Qdrant-Operations.md)
- [Data and collection conventions](../../architecture/Data-and-Collection-Conventions.md)
- [ADR-0011](../../decisions/ADR-0011-Deploy-Qdrant-as-Docker-Compose-Service.md)
- [ADR-0012](../../decisions/ADR-0012-Standardize-Qdrant-Collection-and-Embedding-Metadata.md)
- [ADR-0013](../../decisions/ADR-0013-Qdrant-Snapshot-Retention-and-Cleanup.md)
