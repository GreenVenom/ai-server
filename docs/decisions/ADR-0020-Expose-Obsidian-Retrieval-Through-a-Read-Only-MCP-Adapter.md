---
title: ADR-0020 - Expose Obsidian Retrieval Through a Read-Only MCP Adapter
document: ADR
status: Accepted
created: 2026-07-21
updated: 2026-07-21
platform_version: v0.6.0
owner: GreenVenom
decision_id: ADR-0020
supersedes: null
superseded_by: null
---

# ADR-0020 - Expose Obsidian Retrieval Through a Read-Only MCP Adapter

## Status

Accepted

## Date

2026-07-21

## Context

M05 established the production Obsidian ingestion and retrieval pipeline.

That pipeline owns:

- Vault discovery.
- Inclusion and exclusion rules.
- Markdown parsing.
- Heading-aware chunking.
- Stable document and chunk identities.
- Manifest generation.
- Incremental change detection.
- Embedding generation.
- Qdrant indexing.
- Reconciliation.
- Production-vault synchronization.
- Retrieval behavior.

The production Obsidian index uses:

- Vault ID: `personal-knowledge`
- Collection: `obsidian_chunks_v1`
- Vector name: `text-dense`
- Embedding model: `nomic-embed-text:latest`
- Vector size: 768
- Distance: Cosine

M06 needs to make retrieval available through MCP without creating a second
ingestion or retrieval implementation.

A generalized MCP interface could introduce excessive authority if callers were
allowed to provide:

- Arbitrary filesystem paths.
- Arbitrary vault roots.
- Hidden-file access.
- Arbitrary Qdrant collection names.
- Arbitrary Qdrant administrative requests.
- Arbitrary embedding endpoints or models.
- Full-document dumps.
- Write operations against Obsidian.
- Index mutation.
- Unbounded result counts.

The MCP layer must preserve the M05 contracts and expose only the minimum
read-only retrieval capabilities required by agents.

## Decision

The platform will expose Obsidian retrieval through a thin, read-only MCP
adapter.

The MCP adapter will reuse the established M05 production index and contracts.
It will not implement a separate ingestion pipeline.

### Approved tools

The `obsidian-retrieval` MCP server will expose:

- `obsidian_search`
- `obsidian_get_chunk`
- `obsidian_list_vaults`
- `obsidian_retrieval_status`

### Approved vaults

The production allowlist contains:

```text
personal-knowledge
```

Callers may provide a vault ID only when the tool requires one.

Callers may not provide:

- A filesystem path.
- A vault root.
- A manifest path.
- A collection name.
- A Qdrant URL.
- An Ollama URL.
- An embedding model.
- A vector name.
- A local filename outside the indexed payload.

### Search behavior

`obsidian_search` will:

- Accept an approved vault ID.
- Accept a bounded text query.
- Accept a bounded result limit.
- Generate embeddings through the configured local Ollama endpoint.
- Query only the configured production collection.
- Apply a vault filter.
- Return bounded indexed chunks and source metadata.
- Avoid arbitrary source-file reads.

### Exact chunk behavior

`obsidian_get_chunk` will:

- Accept an approved vault ID.
- Accept a safe chunk identifier.
- Retrieve the indexed point by ID.
- Confirm that the point belongs to the approved vault.
- Return only the approved indexed chunk and payload.

It will not use semantic search as a substitute for exact retrieval.

### Vault inventory behavior

`obsidian_list_vaults` will:

- Return only approved vault IDs.
- Report access as read-only.
- Avoid exposing filesystem roots, manifest paths, or internal storage paths.

### Retrieval status behavior

`obsidian_retrieval_status` will:

- Compare the approved manifest chunk identities with Qdrant point identities.
- Report document count.
- Report chunk count.
- Report reconciliation state.
- Report missing points.
- Report orphan points.
- Report unapproved vault IDs found in the production collection.
- Avoid returning raw manifest contents.

### Read-only boundary

The MCP adapter will not support:

- Creating, editing, moving, or deleting notes.
- Direct source-vault filesystem access.
- Arbitrary file reads.
- Index writes.
- Collection creation or deletion.
- Point mutation.
- Qdrant administrative operations.
- Caller-selected endpoints.
- Caller-selected embedding models.
- Caller-selected collections.
- Caller-selected local paths.

### Ownership boundary

M05 remains the owner of:

- Ingestion.
- Chunking.
- Identities.
- Manifests.
- Synchronization.
- Embedding.
- Index mutation.
- Retrieval contract semantics.

M06 owns only:

- MCP request schemas.
- MCP authorization.
- MCP response envelopes.
- Thin adaptation to the existing retrieval contract.
- MCP-specific tests and operations.

## Rationale

A thin adapter avoids duplicated logic and prevents divergence between native
retrieval behavior and MCP retrieval behavior.

Using vault IDs rather than paths creates a stable authorization boundary.

Using fixed internal endpoints, collection names, embedding models, and vector
names prevents callers from converting the retrieval tool into a generalized
local data-access interface.

Exact chunk retrieval is separated from semantic search so that identity-based
requests remain deterministic.

A status tool is included because reconciliation is operationally significant
and should be inspectable without exposing Qdrant administration.

## Consequences

### Positive

- MCP retrieval remains consistent with the M05 production index.
- No second ingestion implementation needs to be maintained.
- The MCP server cannot be used as a generic filesystem reader.
- The MCP server cannot be used as a generic Qdrant client.
- Vault authorization is explicit.
- Search results remain attributable to indexed sources.
- Exact chunk retrieval is deterministic.
- Reconciliation can be verified through the agent interface.
- The production collection remains protected from mutation.

### Negative

- Only pre-approved indexed vaults are accessible.
- New vaults require configuration and policy updates.
- The adapter depends on the availability of local Ollama and Qdrant.
- Retrieval is limited to indexed content and may not reflect an unsynchronized
  source change.
- Full-document access is intentionally unavailable unless represented by
  approved indexed chunks.
- The MCP server depends on the M05 manifest format and payload contract.

### Risks

- Manifest and Qdrant state may drift.
- Payload schema changes may break the adapter.
- A future developer may duplicate M05 logic inside the MCP layer.
- A poorly validated vault ID could become a path traversal vector.
- Overly broad result payloads could disclose unnecessary note content.

### Mitigations

- Use strict request schemas.
- Validate safe identifiers.
- Maintain an explicit vault allowlist.
- Compare manifest and Qdrant identities.
- Bound result counts.
- Return only indexed payload fields required by the caller.
- Add integration and boundary tests.
- Treat M05 contract changes as coordinated cross-milestone changes.

## Alternatives Considered

### Expose the Obsidian filesystem directly

Rejected because it would permit arbitrary file access and bypass the approved
indexing and exclusion rules.

### Build a second MCP-specific index

Rejected because it would duplicate ingestion, embedding, identity, and
synchronization logic.

### Expose Qdrant directly to the agent

Rejected because it would grant broader query and administration capabilities
than required.

### Reuse only the legacy native `obsidian_search` tool

Rejected because M06 requires a standards-based MCP interface and additional
capabilities such as exact chunk retrieval, vault inventory, and reconciliation
status.

### Add Obsidian write tools in M06

Rejected because write operations require separate authorization, conflict
handling, synchronization, backup, and audit decisions.

## Implementation Notes

MCP server:

```text
obsidian-retrieval
```

Production vault:

```text
personal-knowledge
```

Production collection:

```text
obsidian_chunks_v1
```

Production vector:

```text
text-dense
```

## Related Decisions

- ADR-0018: Use First-Party Local STDIO MCP Servers
- ADR-0019: Standardize MCP Tool Authorization and Exposure
- ADR-0021: Standardize MCP Tool Schemas, Errors, and Logging
