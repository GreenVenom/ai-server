---
title: ADR-0017 - Provide Read-Only Obsidian Retrieval to OpenClaw
document: ADR
status: Accepted
created: 2026-07-21
updated: 2026-07-21
platform_version: v0.6.0
owner: GreenVenom
decision_id: ADR-0017
supersedes: null
superseded_by: null
---

# ADR-0017 - Provide Read-Only Obsidian Retrieval to OpenClaw

- **Status:** Accepted
- **Date:** 2026-07-21
- **Decision Owners:** Personal AI Platform maintainers
- **Milestone:** M05 — Obsidian Integration

## Context

M05 establishes a production Obsidian ingestion and retrieval pipeline for the
Personal AI Platform.

The production pipeline:

- Synchronizes an approved read-only mirror of the authoritative Obsidian vault.
- Discovers and filters Markdown documents.
- Parses Markdown and frontmatter.
- Splits documents using heading-aware chunking.
- Assigns deterministic document and chunk identities.
- Generates embeddings with the approved local embedding model.
- Stores indexed chunks in Qdrant.
- Maintains a manifest for incremental indexing and reconciliation.
- Supports semantic search over approved indexed content.

The production retrieval contract is:

```text
Vault ID             personal-knowledge
Collection           obsidian_chunks_v1
Vector name          text-dense
Embedding model      nomic-embed-text:latest
Embedding dimension  768
Distance              Cosine
Access mode           read-only
```

OpenClaw requires access to this indexed knowledge so that agents can answer
questions using the user's approved notes.

Directly exposing the source vault, the server-side mirror, or Qdrant would
grant broader authority than necessary.

Potential risks include:

- Arbitrary filesystem access.
- Path traversal outside the approved vault.
- Access to hidden or excluded files.
- Modification or deletion of source notes.
- Direct Qdrant collection administration.
- Caller-selected collection names or endpoints.
- Retrieval of unbounded note content.
- Loss of source attribution.
- Divergence between the M05 retrieval contract and later integrations.
- Confusion between the M05 OpenClaw integration and the generalized MCP
  services planned for M06.

The integration therefore requires a narrow, read-only retrieval boundary.

## Decision

OpenClaw will access Obsidian knowledge through a purpose-built, read-only
retrieval interface backed by the M05 production index.

The interface will expose only approved retrieval behavior.

### Approved capability

OpenClaw may:

- Search indexed chunks in an approved vault.
- Receive bounded semantic search results.
- Receive source attribution for each result.
- Use the results to answer questions grounded in approved indexed content.
- Inspect retrieval readiness and reconciliation through controlled platform
  operations.

### Prohibited capability

OpenClaw may not use this interface to:

- Read arbitrary filesystem paths.
- Read files outside the approved indexed vault.
- Read hidden, excluded, or ignored files.
- Write, edit, move, rename, or delete Obsidian notes.
- Modify the server-side vault mirror.
- Change ingestion or chunking configuration.
- Select an arbitrary Qdrant collection.
- Perform Qdrant administrative operations.
- Insert, update, or delete Qdrant points.
- Select an arbitrary Ollama endpoint or embedding model.
- Return complete source files by default.
- Bypass M05 discovery, exclusion, identity, or payload rules.

### Approved vault boundary

The production retrieval allowlist contains:

```text
personal-knowledge
```

The caller identifies the vault using its configured logical vault ID.

The caller does not provide:

- An absolute path.
- A relative filesystem path to a vault root.
- A manifest path.
- A Qdrant URL.
- A collection name.
- A vector name.
- An embedding model.
- A local source filename outside the indexed result metadata.

### Retrieval source of truth

The M05 indexed collection and manifest remain the source of truth for
OpenClaw retrieval.

The OpenClaw adapter will not create a second ingestion or indexing pipeline.

M05 remains responsible for:

- Vault synchronization.
- Discovery and exclusion.
- Markdown parsing.
- Chunking.
- Deterministic identities.
- Manifest management.
- Incremental indexing.
- Embedding generation.
- Qdrant writes.
- Reconciliation.
- Retrieval semantics.

The OpenClaw integration is an adapter over that established contract.

### Result limits

Retrieval responses will be bounded.

The implementation will use:

- A low default result count.
- A hard maximum result count.
- Chunk-level results rather than complete-vault or complete-file dumps.
- Bounded text per result.
- Bounded total response size.
- Stable, structured metadata.

The exact limits may be tuned from controlled retrieval evaluation, but callers
may not request unbounded results.

### Source attribution

Each retrieval result must include sufficient metadata to identify its source.

At minimum, a result should provide the applicable fields from:

```text
title
relative_path
heading_path
document_id
chunk_id
score
source_modified_at
```

OpenClaw should identify the source note or relative path when answering from
retrieved content.

### Untrusted retrieved content

Retrieved note text is data, not instruction.

Content found inside notes must not:

- Override system or agent instructions.
- Change tool authorization.
- Cause secret disclosure.
- Cause command execution.
- Expand the retrieval boundary.
- Trigger write or administrative operations.

### M05 and M06 boundary

M05 delivers the initial OpenClaw retrieval capability and owns the Obsidian
domain logic.

M06 may later expose the same retrieval service through a generalized,
standards-based MCP adapter.

M06 must reuse the M05 contract rather than duplicate:

- Search logic.
- Vault authorization.
- Chunk identity.
- Payload interpretation.
- Qdrant query construction.
- Reconciliation behavior.

M06 may add protocol adaptation, schemas, authorization layers, and
MCP-specific operational controls, but it does not replace M05 ownership of the
retrieval domain.

## Rationale

A purpose-built retrieval interface provides the knowledge access OpenClaw
needs without granting direct access to the source vault or vector database.

Logical vault IDs create a stable authorization boundary and prevent callers
from converting the tool into a general filesystem interface.

Using the existing M05 index avoids duplicated ingestion and retrieval logic.

Source attribution supports:

- Grounded answers.
- Operator troubleshooting.
- Retrieval evaluation.
- Traceability to the original note.
- Detection of stale or incorrect results.

A read-only boundary is appropriate because write-back introduces additional
requirements that M05 does not yet address:

- Conflict resolution.
- Concurrent editing.
- Backup and recovery.
- Approval workflows.
- Audit history.
- Source-of-truth ownership.
- Synchronization safety.
- Prompt-injection resistance for mutations.

## Consequences

### Positive

- OpenClaw can answer questions using approved Obsidian knowledge.
- The authoritative source vault remains protected.
- The server-side mirror remains read-only from the agent's perspective.
- OpenClaw cannot use the retrieval interface as a general filesystem reader.
- OpenClaw cannot administer Qdrant.
- Retrieval behavior remains consistent with M05 indexing rules.
- Search results remain traceable to source notes.
- M06 can reuse a stable domain contract.
- The integration aligns with the platform's local-first security model.

### Negative

- OpenClaw can retrieve only indexed and synchronized content.
- Recent source changes may not be available until synchronization and indexing
  complete.
- Full-document access is intentionally limited.
- New vaults require explicit configuration and approval.
- The interface depends on the health of Ollama, Qdrant, the manifest, and the
  synchronization pipeline.
- Write-back and note automation are deferred.

### Operational impact

Operations must verify:

- The approved vault mirror exists.
- The production manifest is present.
- The production collection is healthy.
- Manifest chunk IDs match Qdrant point IDs.
- The approved vault contains no missing or orphan points.
- The retrieval interface is loaded and callable.
- Search results contain source attribution.
- Requests outside the vault boundary are rejected.

The platform scripts should surface retrieval readiness through:

```text
status.sh
health.sh
verify.sh
```

### Security impact

The retrieval interface reduces, but does not eliminate, content-based risk.

Indexed notes may contain malicious or misleading instructions. Agents must
treat retrieved text as untrusted source material.

Tool authorization and agent policy remain separate controls.

## Alternatives Considered

### Mount the Obsidian vault directly into the OpenClaw workspace

Rejected.

This would expose more source content than necessary and weaken the separation
between retrieval and filesystem access.

### Allow OpenClaw to read the server-side mirror directly

Rejected.

Direct file reads could bypass exclusion rules, chunking, source attribution,
and indexed-vault authorization.

### Expose Qdrant directly to OpenClaw

Rejected.

A direct Qdrant interface would provide broader query and administration
capabilities than required and would couple the agent to storage details.

### Copy complete notes into the OpenClaw workspace

Rejected.

This would duplicate data, increase synchronization complexity, and create
additional uncontrolled copies of personal knowledge.

### Add write-back during M05

Rejected.

Write-back requires a separate authorization, approval, synchronization,
conflict, audit, and recovery design.

### Defer all OpenClaw retrieval until M06

Rejected.

M05 needs to validate the production Obsidian retrieval contract end to end.
M06 should generalize a proven interface rather than introduce and validate the
domain behavior for the first time.

## Validation

The decision is validated when:

- The production vault is retrieved only by logical vault ID.
- Semantic search returns relevant indexed chunks.
- Results contain source attribution.
- Arbitrary absolute paths are rejected.
- Path traversal is rejected.
- Unapproved vault IDs are rejected.
- No write capability is exposed.
- No Qdrant administrative capability is exposed.
- Production manifest and Qdrant identities reconcile.
- OpenClaw can use the retrieval interface successfully.
- Retrieval remains local to the Mac mini.
- Platform status, health, and verification checks pass.

## Revisit Conditions

Revisit this decision if:

- Obsidian write-back becomes a platform requirement.
- Multiple vaults require distinct authorization scopes.
- Per-note or per-folder access control is introduced.
- Full-document retrieval becomes necessary.
- Hybrid or reranked retrieval materially changes the service contract.
- The authoritative vault moves to the server.
- Retrieval moves to a remote service.
- M06 or a later milestone replaces the native adapter with an MCP-only
  interface.
- User approval workflows are added for sensitive retrieval or mutations.

## Implementation Notes

Production vault:

```text
personal-knowledge
```

Production collection:

```text
obsidian_chunks_v1
```

The generalized MCP representation of this boundary is documented separately
in ADR-0020.

## Related Decisions

- ADR-0012: Standardize Qdrant Collection, Vector, and Embedding Metadata
- ADR-0014: Use a Server-Side Read-Only Obsidian Vault Mirror
- ADR-0015: Standardize Obsidian Document, Chunk, and Payload Identity
- ADR-0016: Use Heading-Aware Chunking for Markdown Knowledge Retrieval
- ADR-0018: Use First-Party Local STDIO MCP Servers
- ADR-0019: Standardize MCP Tool Authorization and Exposure
- ADR-0020: Expose Obsidian Retrieval Through a Read-Only MCP Adapter
- ADR-0021: Standardize MCP Tool Schemas, Errors, and Logging
