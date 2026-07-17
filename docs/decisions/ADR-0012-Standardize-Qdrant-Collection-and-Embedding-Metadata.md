---
title: ADR-0012 - Standardize Qdrant Collection, Vector, and Embedding Metadata
document: ADR
status: Accepted
created: 2026-07-17
updated: 2026-07-17
platform_version: v0.4.0
owner: GreenVenom
decision_id: ADR-0012
supersedes:
superseded_by:
---

# ADR-0012 - Standardize Qdrant Collection, Vector, and Embedding Metadata

- **Status:** Accepted
- **Date:** 2026-07-17
- **Decision Owners:** Personal AI Platform maintainers
- **Milestone:** M04 — Qdrant Vector Database

## Context

M04 establishes the vector-storage contract that future milestones will use.

M05 will ingest Obsidian content, and later OpenClaw and MCP integrations may create or query additional collections. Without common conventions, each integration could choose incompatible collection names, vector names, identifiers, payload fields, hashes, timestamps, and embedding metadata.

The initial validated embedding contract is:

```text
Embedding model      nomic-embed-text:latest
Embedding dimension  768
Distance metric      Cosine
Vector name          text-dense
```

The conventions must support:

- deterministic re-indexing;
- duplicate prevention;
- traceability to original source material;
- payload validation;
- embedding-model migrations;
- collection schema evolution;
- portable backup manifests;
- multiple future ingestion domains.

## Decision

The Personal AI Platform will standardize Qdrant collection naming, named vectors, deterministic identifiers, payload metadata, content hashing, and timestamps.

## Collection Naming

Collections will use:

```text
<domain>_<purpose>_v<schema-version>
```

Examples:

```text
validation_m04_v1
obsidian_chunks_v1
project_docs_v1
```

The collection name will represent the data domain, purpose, and application schema version.

The Qdrant software version will not be encoded in collection names.

A new collection schema version will be created when an incompatible schema or vector change cannot be introduced safely in place.

## Named Vector

The primary dense text vector will be named:

```text
text-dense
```

Its current contract is:

```text
Model       nomic-embed-text:latest
Dimension   768
Distance    Cosine
```

Named vectors are mandatory even when a collection contains only one vector representation. This avoids ambiguity and permits future additional dense, sparse, or migrated vector spaces.

## Deterministic Point Identity

Point IDs will be deterministic UUIDv5 values.

Permanent UUID namespace:

```text
b83a8b73-03e0-5f87-a8fb-3f8996cf6f21
```

Point identity input:

```text
source_type|source_id|chunk_id
```

Document identity input:

```text
source_type|source_id
```

The same source and chunk must always produce the same point ID.

Different chunks must produce different point IDs.

This enables idempotent upserts and prevents duplicate points when content is reprocessed.

## Required Payload Fields

Every indexed text point must contain:

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

These fields define the minimum retrieval and traceability contract.

Additional domain-specific fields may be added, including:

```text
vault
path
tags
headings
links
aliases
content_type
language
access_scope
```

Optional fields must not replace or reinterpret required fields.

## Content Normalization and Hashing

`content_hash` will be a SHA-256 digest of normalized text.

Normalization must be deterministic and documented by the ingestion implementation. At minimum, equivalent source text must normalize consistently before hashing.

The hash is used to:

- detect unchanged chunks;
- avoid unnecessary re-embedding;
- verify payload integrity;
- support incremental indexing;
- diagnose source-to-index drift.

## Timestamps

Timestamps will use UTC RFC 3339 format and end in `Z`.

Example:

```text
2026-07-17T04:16:04Z
```

`source_modified_at` represents the source material's modification time when known.

`indexed_at` represents when the point was generated or updated in Qdrant.

## Schema Evolution

Additive optional payload fields may be introduced without a new collection when they do not change existing field meaning or vector compatibility.

A new collection version is required when:

- the vector dimension changes;
- the distance metric changes;
- required payload semantics change incompatibly;
- point identity rules change;
- chunk identity rules change;
- an embedding migration cannot be completed safely in place.

A new named vector may be added for a controlled embedding-model migration when Qdrant supports the change and all affected points can be populated.

Collection aliases may be used later for atomic application cutover.

## Deletion and Re-indexing

Reprocessing the same chunk will upsert the same deterministic point ID.

When a source document is removed, all points associated with its deterministic `document_id` must be deleted.

When chunk boundaries change, stale chunk IDs must be removed after the replacement set is successfully indexed.

## Rationale

These conventions were selected because they:

- make ingestion idempotent;
- provide stable point identities;
- allow source-level deletion;
- make payloads auditable;
- support incremental indexing;
- make embedding dependencies explicit;
- provide a controlled migration path;
- reduce coupling between M05, OpenClaw, and MCP integrations;
- make backup manifests and restore validation meaningful.

## Alternatives Considered

### 1. Sequential integer point IDs

Rejected.

Sequential IDs are easy to create but do not remain stable across re-indexing and require a separate identity registry.

### 2. Random UUID point IDs

Rejected.

Random IDs prevent deterministic upserts and make duplicate detection more difficult.

### 3. Unnamed vectors

Rejected.

Unnamed vectors introduce ambiguity and complicate future vector migration or multi-vector collections.

### 4. Encode the embedding model in the collection name

Rejected as the default convention.

Embedding model metadata belongs in the vector and payload contract. Collection versioning should represent compatibility, not reproduce every runtime detail in the name.

### 5. Store only vectors and minimal source IDs

Rejected.

Insufficient payload metadata would make debugging, source tracing, incremental indexing, integrity checks, and migration difficult.

### 6. Use local timestamps without timezone markers

Rejected.

Local timestamps are ambiguous across systems, daylight-saving changes, backups, and future migrations.

## Consequences

### Positive

- Re-indexing is deterministic.
- Duplicate points are avoided.
- Source documents and chunks are traceable.
- Content changes can be detected through hashes.
- Retrieval clients can depend on a stable payload contract.
- Embedding migrations have an explicit decision boundary.
- M05 can begin without redesigning Qdrant conventions.

### Negative

- Ingestion code must implement normalization and UUIDv5 generation consistently.
- Required metadata increases payload size.
- Incompatible changes require migration or collection rebuilds.
- Collection schema discipline must be maintained across future integrations.

### Operational

Validation scripts must confirm:

- collection naming;
- vector name;
- vector dimension;
- distance metric;
- stable UUIDv5 generation;
- unique chunk identities;
- required payload fields;
- content hashes;
- timestamp formatting;
- semantic search;
- metadata filtering;
- deterministic point deletion.

## Validation

The decision has been validated by the M04.5 integration smoke test.

Validated outcomes include:

```text
Passed checks          20
Failed checks          0
Vector name            text-dense
Vector dimension       768
Distance               Cosine
UUIDv5 stability       passed
UUID chunk uniqueness  passed
Required fields        passed
SHA-256 validation     passed
RFC 3339 timestamps    passed
Semantic ranking       passed
Payload filtering      passed
Deterministic deletion passed
```

## Revisit Conditions

Revisit this decision if:

- the primary embedding model changes;
- sparse or hybrid retrieval becomes a platform requirement;
- chunk identity semantics change;
- access-control metadata becomes mandatory;
- multiple vector stores must share one schema;
- Qdrant adds a feature that materially improves migration;
- production corpus scale reveals unacceptable payload overhead.


## Related documentation

- [Data and collection conventions](../architecture/Data-and-Collection-Conventions.md)
- [M04 milestone record](../milestones/M04-Qdrant.md)
- [Qdrant operations](../operations/Qdrant-Operations.md)
- [ADR-0011](ADR-0011-Deploy-Qdrant-as-Docker-Compose-Service.md)
- [ADR-0013](ADR-0013-Qdrant-Snapshot-Retention-and-Cleanup.md)
