---
title: ADR-0011 - Deploy Qdrant as a Docker Compose Service
document: ADR
status: Accepted
created: 2026-07-17
updated: 2026-07-17
platform_version: v0.4.0
owner: Personal AI Platform maintainers
decision_id: ADR-0011
supersedes:
superseded_by:
---

# ADR-0011 - Deploy Qdrant as a Docker Compose Service

- **Status:** Accepted
- **Date:** 2026-07-17
- **Decision Owners:** Personal AI Platform maintainers
- **Milestone:** M04 — Qdrant Vector Database

## Context

The Personal AI Platform requires a persistent vector database for semantic retrieval, future Obsidian ingestion, and later OpenClaw and MCP integrations.

The existing platform runs on a Mac mini under the dedicated standard user account:

```text
openclaw
```

Docker Desktop is already the approved container runtime. Under ADR-0010, Docker Desktop starts automatically after the `openclaw` user logs in. Docker-backed services therefore become available after the authenticated user-session dependency is satisfied.

The Qdrant deployment must:

- run reproducibly;
- remain isolated from LAN and Tailscale interfaces;
- persist collection data across container recreation;
- restart automatically when Docker becomes available;
- expose stable local REST and gRPC endpoints;
- support portable collection snapshots;
- integrate with existing platform health and verification scripts;
- avoid introducing an additional native macOS service-management model.

The deployed Qdrant version is:

```text
1.18.2
```

## Decision

Qdrant will run as a single-node Docker Compose service under the `openclaw` user's Docker Desktop environment.

The service will use:

```text
Image             qdrant/qdrant:1.18.2
REST endpoint     127.0.0.1:6333
gRPC endpoint     127.0.0.1:6334
Restart policy    always
Telemetry         disabled
Live data volume  personal-ai-qdrant-storage
Snapshot export   ~/server/backups/qdrant/snapshots
```

The Qdrant image will be version-pinned. The committed Compose definition will not use an unpinned `latest` tag.

Published ports will bind explicitly to loopback:

```yaml
ports:
  - "127.0.0.1:6333:6333"
  - "127.0.0.1:6334:6334"
```

Qdrant live storage will use the Docker named volume:

```text
personal-ai-qdrant-storage
```

The named volume is the authoritative live data store. It will not be treated as the portable backup mechanism.

Portable collection backups will be created through Qdrant's snapshot API and downloaded to:

```text
~/server/backups/qdrant/snapshots
```

Snapshot manifests will be stored under:

```text
~/server/backups/qdrant/manifests
```

The service lifecycle remains dependent on Docker Desktop:

```text
macOS boots
    ↓
FileVault is unlocked
    ↓
openclaw user logs in
    ↓
Docker Desktop starts
    ↓
Qdrant starts under restart: always
    ↓
Qdrant readiness and API checks pass
```

Qdrant will remain a local-only service during M04. API authentication may be introduced before application integrations require a broader trust boundary.

## Rationale

Docker Compose was selected because it:

- matches the platform's existing container runtime;
- provides a reproducible and reviewable service definition;
- supports explicit image versioning;
- supports loopback-only port publication;
- supports an automatic restart policy;
- isolates Qdrant runtime dependencies from macOS;
- provides a stable named volume for live data;
- simplifies upgrades, rollback, inspection, and recreation;
- avoids a second custom LaunchAgent or LaunchDaemon implementation;
- aligns with future containerized platform services.

A Docker named volume was selected for live Qdrant data because it resolved the filesystem compatibility warning observed with the earlier host filesystem approach and provides Qdrant with storage semantics controlled by Docker's Linux virtual machine.

Portable recovery is kept separate from live storage through native Qdrant snapshots and host-side manifests.

## Alternatives Considered

### 1. Install Qdrant as a native macOS process

Rejected.

This would introduce a second service-management pattern, custom startup configuration, separate dependency management, and additional upgrade procedures. The platform already has an approved Docker runtime.

### 2. Use an unpinned `latest` image

Rejected.

An unpinned image could change runtime behavior without a corresponding repository change, complicating validation and rollback.

### 3. Publish Qdrant on all host interfaces

Rejected.

The platform does not require direct LAN or Tailscale access to Qdrant. Broader publication would unnecessarily expand the attack surface.

### 4. Use a host bind mount for live Qdrant storage

Superseded by the deployed named-volume design.

A host bind mount was considered because it makes files directly visible beneath `~/server`. During implementation, the Docker named volume provided the cleaner and more reliable storage behavior for Qdrant's live database files.

Portable snapshots and manifests provide the required host-visible recovery artifacts.

### 5. Run Qdrant in Qdrant Cloud

Rejected for the current milestone.

The platform is local-first, the expected data volume is modest, and cloud hosting would introduce external dependency, credentials, network exposure, and recurring cost.

### 6. Run a clustered or highly available Qdrant deployment

Deferred.

The personal server currently uses one Mac mini and does not require distributed consensus or multi-node availability.

## Consequences

### Positive

- Qdrant deployment is reproducible.
- The image version is explicit.
- REST and gRPC endpoints remain loopback-only.
- Collection data survives container recreation.
- Qdrant restarts automatically after Docker Desktop becomes available.
- Live storage uses Docker-managed filesystem semantics.
- Portable snapshots remain available outside the live volume.
- Existing Docker and platform operational tooling can manage Qdrant.

### Negative

- Qdrant is unavailable before the `openclaw` account logs in and Docker Desktop starts.
- The live named volume is not directly browsable as a normal directory under `~/server`.
- Docker Desktop remains a runtime dependency.
- Full machine recovery requires both configuration and portable backup artifacts, not merely the Compose file.

### Operational

The platform must verify:

- the expected image tag;
- container health;
- restart policy;
- loopback-only port bindings;
- named-volume attachment;
- REST readiness;
- gRPC port availability;
- Qdrant version;
- snapshot creation and restore.

After restart or login, the expected sequence is:

```text
Docker available
Qdrant container running
Qdrant container healthy
REST readiness passed
gRPC port reachable
Collections available
```

## Validation

The decision has been validated by:

- deploying Qdrant 1.18.2 through Docker Compose;
- confirming healthy container state;
- confirming REST on `127.0.0.1:6333`;
- confirming gRPC on `127.0.0.1:6334`;
- confirming telemetry is disabled;
- confirming the filesystem warning is resolved;
- confirming collection persistence;
- creating and querying a validation collection;
- creating, downloading, verifying, and restoring a native collection snapshot.

## Revisit Conditions

Revisit this decision if:

- Qdrant must run before any user logs in;
- Docker Desktop is replaced;
- the platform migrates to Linux;
- direct remote Qdrant access becomes necessary;
- Qdrant authentication becomes mandatory for local clients;
- the named volume prevents an acceptable disaster-recovery design;
- high availability or clustering becomes a requirement;
- storage performance or scale exceeds the current single-node design.

## Related documentation

- [Documentation map](../README.md)
