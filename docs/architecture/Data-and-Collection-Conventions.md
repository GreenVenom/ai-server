---
title: Data and Collection Conventions
document: Architecture
status: Active
created: 2026-07-17
updated: 2026-07-17
platform_version: v0.3.0
owner: Personal AI Platform maintainers
milestone: M04 - Qdrant Vector Database
schema_version: 1
embedding_model: nomic-embed-text:latest
embedding_dimension: 768
---

# Data and Collection Conventions

## Purpose

This document defines the naming, identity, vector, payload, hashing, timestamp, and schema-evolution conventions used by the Personal AI Platform when storing text embeddings in Qdrant.

These conventions form the contract between:

```text
Source documents
    ↓
Text normalization and chunking
    ↓
nomic-embed-text:latest
    ↓
Qdrant collections
    ↓
Retrieval clients such as OpenClaw
```

M05 Obsidian ingestion and later retrieval integrations must follow this contract unless a newer documented schema supersedes it.

## Current Qdrant contract

| Property | Value |
|---|---|
| Qdrant deployment | Docker Compose |
| Qdrant version | `1.18.2` |
| REST endpoint | `127.0.0.1:6333` |
| gRPC endpoint | `127.0.0.1:6334` |
| Live storage | Docker named volume `personal-ai-qdrant-storage` |
| Snapshot export path | `~/server/backups/qdrant/snapshots` |
| Embedding endpoint | `http://127.0.0.1:11434/api/embed` |
| Embedding model | `nomic-embed-text:latest` |
| Embedding dimension | `768` |
| Default dense-vector name | `text-dense` |
| Default distance metric | `Cosine` |

The vector dimension was measured from the installed model and confirmed stable across multiple inputs.

## Collection naming convention

Collection names use:

```text
<domain>_<purpose>_v<schema-version>
```

Examples:

```text
validation_m04_v1
obsidian_chunks_v1
project_docs_v1
openclaw_memory_v1
```

### Rules

1. Use lowercase characters.
2. Separate components with underscores.
3. Include the logical collection schema version.
4. Do not encode the Qdrant software version in a collection name.
5. Do not encode an embedding-model version unless the collection is intentionally model-specific.
6. Create a new collection when an incompatible schema, vector dimension, or chunking strategy is introduced.
7. Temporary automated-test collections may use an explicit `_test` suffix.

The accepted disposable smoke-test collection is:

```text
validation_m04_v1_test
```

The existing manually created `m04_validation` collection is considered a development artifact and does not define the production naming standard.

## Vector naming convention

The default dense text vector is:

```text
text-dense
```

Current vector contract:

```text
name:       text-dense
model:      nomic-embed-text:latest
dimension:  768
distance:   Cosine
```

Future vector names may include:

```text
text-dense-v2
text-sparse
image-dense
```

A point payload must still record the exact embedding model and dimension even though the collection schema validates the vector dimension.

## Deterministic point identity

Point IDs use UUIDv5 so the same logical chunk always produces the same Qdrant point ID.

### Namespace UUID

```text
b83a8b73-03e0-5f87-a8fb-3f8996cf6f21
```

This namespace is a permanent project constant. It must not change after production indexing begins.

### Identity input

```text
source_type|source_id|chunk_id
```

Example:

```text
obsidian|Projects/AI Server.md|0003
```

### Algorithm

```python
uuid.uuid5(
    UUID("b83a8b73-03e0-5f87-a8fb-3f8996cf6f21"),
    "obsidian|Projects/AI Server.md|0003",
)
```

Validated behavior:

```text
same source and chunk → same UUID
different chunk       → different UUID
```

The UUID namespace and identity-string format are part of the schema contract.

## Document identity

`document_id` identifies the logical source document shared by all of its chunks.

Use UUIDv5 with:

```text
source_type|source_id
```

Example:

```text
obsidian|Projects/AI Server.md
```

This allows all chunks from one source document to be queried, replaced, or deleted together.

## Required payload fields

Every indexed text chunk must contain the following payload fields.

| Field | Type | Meaning |
|---|---|---|
| `schema_version` | integer | Payload schema version; initially `1` |
| `source_type` | string | Source family such as `obsidian`, `project_doc`, or `validation` |
| `source_id` | string | Stable source identifier, usually a normalized relative path |
| `document_id` | UUID string | Deterministic UUID shared by all chunks from one document |
| `chunk_id` | string | Stable chunk identifier within the document |
| `title` | string | Human-readable document or section title |
| `text` | string | Exact normalized text used to produce the embedding |
| `content_hash` | string | SHA-256 hash of normalized UTF-8 chunk text |
| `source_modified_at` | RFC 3339 string | Original source modification time in UTC |
| `indexed_at` | RFC 3339 string | Time the point was indexed in UTC |
| `embedding_model` | string | Exact embedding model identifier |
| `embedding_dimension` | integer | Dimension of the stored vector |

### Validation requirements

- No required field may be absent.
- `schema_version` must be a positive integer.
- `document_id` and the Qdrant point ID must be valid UUIDs.
- `content_hash` must be a lowercase, 64-character SHA-256 hexadecimal string.
- `source_modified_at` and `indexed_at` must use UTC RFC 3339 timestamps ending in `Z`.
- `embedding_dimension` must match the collection vector schema.
- `text` must match the text used to create the embedding.

## Optional payload fields

M05 and later integrations may add:

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
chunk_index
chunk_count
```

Adding optional fields does not by itself require a new collection version.

## Text normalization

Before hashing or embedding a text chunk:

1. Convert all line endings to `\n`.
2. Remove trailing whitespace from each line.
3. Remove leading and trailing blank space from the full chunk.
4. Preserve meaningful internal spacing.
5. Encode the result as UTF-8.

Reference implementation:

```python
normalized = "\n".join(
    line.rstrip()
    for line in text.replace("\r\n", "\n").replace("\r", "\n")
    .strip()
    .splitlines()
)
```

The normalized text is stored in the payload and is the exact input used to produce the embedding.

## Content hashing

Use SHA-256 over normalized UTF-8 text:

```python
hashlib.sha256(normalized.encode("utf-8")).hexdigest()
```

Validated example:

```text
OpenClaw provides the orchestration and agent layer.
Its gateway listens only on localhost.
```

Produces:

```text
ab3558952d26d13697c25dcec8dae438c4428959a535dc425fc0f6230eea45ef
```

The hash is used to determine whether a chunk changed and requires re-embedding.

## Timestamp convention

Store timestamps in UTC RFC 3339 form:

```text
YYYY-MM-DDTHH:MM:SSZ
```

Example:

```text
2026-07-17T04:16:04Z
```

Reference implementation:

```python
datetime.now(timezone.utc).replace(
    microsecond=0
).isoformat().replace("+00:00", "Z")
```

Local timezone offsets must not be stored in canonical payload timestamps.

## Example compliant payload

```json
{
  "schema_version": 1,
  "source_type": "obsidian",
  "source_id": "Projects/AI Server.md",
  "document_id": "3fc5e98a-5050-51ee-bdac-a967817ddf2c",
  "chunk_id": "0003",
  "title": "Qdrant Architecture",
  "text": "Qdrant provides persistent vector storage for the personal AI platform.",
  "content_hash": "4b3f9f5f1b494e0e6e6a4191cb92d44a92b91a0ea938c558176d7dbea392ddee",
  "source_modified_at": "2026-07-17T02:45:00Z",
  "indexed_at": "2026-07-17T04:16:04Z",
  "embedding_model": "nomic-embed-text:latest",
  "embedding_dimension": 768,
  "path": "Projects/AI Server.md",
  "content_type": "markdown"
}
```

## Schema evolution

### Additive optional fields

Adding an optional payload field does not require a new collection.

### Required-field changes

Changing the meaning, type, format, or identity semantics of a required field requires a new schema version and normally a new collection.

Example:

```text
obsidian_chunks_v1
obsidian_chunks_v2
```

### Embedding dimension changes

A vector-dimension change requires either:

- a new named vector with a new schema, or
- a new collection.

For the first production migrations, a new collection is preferred because it is simpler to validate and roll back.

### Embedding model changes

Different embedding models must not be silently mixed within the same named vector, even when their dimensions match.

Use either:

- a distinct named vector, or
- a rebuilt versioned collection.

### Chunking changes

A materially different chunking strategy requires a new collection schema version because it changes:

- point identity;
- document coverage;
- retrieval granularity;
- ranking behavior;
- update and deletion semantics.

### Point identity changes

Changing the UUID namespace or identity-input format requires a new schema version and full re-index.

## Re-indexing behavior

When a chunk is reprocessed:

1. Normalize the source text.
2. Compute its deterministic point ID.
3. Compute its SHA-256 content hash.
4. Compare the hash with the stored point.
5. Skip embedding when the hash and embedding contract are unchanged.
6. Upsert the point when its text or required metadata changed.
7. Delete old points that no longer correspond to a current source chunk.

Because point IDs are deterministic, re-indexing is idempotent.

## Deletion behavior

Document deletion must remove all points sharing the document’s `document_id` or stable source identity.

Chunk deletion must remove the deterministic point ID derived from:

```text
source_type|source_id|chunk_id
```

Deletion workflows must be tested before M05 production ingestion is enabled.

## Payload indexing

Payload indexes should be added only for fields used in filters or high-frequency lookups.

Likely initial index candidates:

```text
source_type
source_id
document_id
schema_version
content_hash
```

Do not create indexes for every payload field during M04. Real M05 query patterns should guide optimization.

## Security and privacy

- Qdrant remains bound to loopback.
- Secrets must not be stored in collection payloads.
- Snapshot files must not be committed to Git.
- Payloads may contain source text and therefore inherit the source document’s sensitivity.
- Future `access_scope` metadata must be enforced by the retrieval layer, not treated as protection by itself.

## Acceptance contract

```text
Collection pattern       <domain>_<purpose>_v<schema>
Dense vector name        text-dense
Point ID                  deterministic UUIDv5
Point identity input      source_type|source_id|chunk_id
Document ID               deterministic UUIDv5
Document identity input   source_type|source_id
UUID namespace            b83a8b73-03e0-5f87-a8fb-3f8996cf6f21
Content hash              SHA-256
Timestamp format          UTC RFC 3339
Payload schema version    1
Embedding model           nomic-embed-text:latest
Embedding dimension       768
Distance metric           Cosine
```

These conventions are accepted for M04 and govern M05 unless superseded by a documented architecture decision.

## Related documentation

- [M04 Qdrant milestone](../milestones/M04-Qdrant.md)
- [System overview](System-Overview.md)
- [Directory layout](Directory-Layout.md)
- [OpenClaw architecture](OpenClaw-Architecture.md)
- [Platform glossary](../glossary/Glossary.md)
