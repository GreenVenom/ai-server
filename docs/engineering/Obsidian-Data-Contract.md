---
title: Obsidian Data Contract
document: Reference
status: Active
created: 2026-07-18
updated: 2026-07-18
platform_version: v0.5.0
owner: GreenVenom
---

# Obsidian Data Contract

## Purpose

This reference defines the parsed-document, retrieval-chunk, payload, manifest, and reconciliation contracts for the Obsidian ingestion service.

## Document contract

Each parsed document records, at minimum:

- vault ID;
- normalized relative path;
- deterministic document ID;
- title;
- source body;
- headings;
- frontmatter metadata;
- tags;
- aliases;
- wikilinks and Markdown links;
- source-content hash;
- metadata hash;
- inclusion decision;
- parser issues.

## Chunk contract

Each retrieval chunk records:

- deterministic chunk ID;
- parent document ID;
- vault ID;
- relative path;
- title;
- heading context;
- chunk text;
- ordinal or stable chunk identity data;
- source hash;
- metadata hash;
- tags;
- embedding model;
- chunking profile;
- payload schema version.

## Payload schema

Production payloads use schema version 2. Consumers must treat unknown schema versions as incompatible unless explicitly supported.

Representative payload:

```json
{
  "schema_version": 2,
  "vault_id": "personal-knowledge",
  "document_id": "<uuid>",
  "chunk_id": "<uuid>",
  "relative_path": "TO-DOs.md",
  "title": "TO-DOs",
  "heading": "TO-DOs",
  "chunk_text": "...",
  "tags": [],
  "source_hash": "<sha256>",
  "metadata_hash": "<sha256>",
  "embedding_model": "nomic-embed-text:latest",
  "chunking_profile": "heading-aware-v1"
}
```

## Manifest contract

The manifest is the reconciliation source for derived index state. It is not the authoritative source of note content.

The manifest must:

- identify the vault and collection;
- record every included document;
- record each document's hashes;
- record all active chunk IDs;
- be written atomically;
- use file mode `0600`;
- reconcile exactly with Qdrant points filtered by vault ID.

## Change classification

| Classification | Required action |
|---|---|
| Added | Parse, chunk, embed, and upsert |
| Source changed | Rebuild document chunks and remove stale chunk IDs |
| Metadata changed | Update affected payloads; embed only when chunk content changes |
| Unchanged | No embedding or Qdrant write |
| Excluded | Remove previously indexed points |
| Deleted | Remove points when deletion policy permits |
| Rename | Treat as addition plus deletion unless identity policy changes |

## Deletion safety

The default maximum deletion percentage is 10 percent. A proposed reconciliation above this threshold must fail unless an explicit approval option is supplied.

## Related documentation

- [Obsidian integration architecture](../architecture/Obsidian-Integration.md)
- [M05 milestone record](../operations/milestones/M05-Obsidian-Integration.md)
