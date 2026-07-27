# ADR-0022: Obsidian Index V2 Cutover and V1 Rollback Retention

- **Status:** Accepted
- **Date:** 2026-07-27
- **Decision makers:** Personal AI Server project maintainers
- **Related:** ADR-0012, ADR-0017, ADR-0018, ADR-0019, ADR-0020, ADR-0021

## Context

The production Obsidian retrieval index previously used the `obsidian_chunks_v1`
Qdrant collection and its original manifest root,
`data/obsidian/manifests`. A rebuilt production index was created in the
separate `obsidian_chunks_v2` collection, with manifests stored under
`data/obsidian/manifests-v2`.

The V2 rebuild was validated against the `personal-knowledge` vault before
cutover. It produced 39 manifest documents and 265 Qdrant chunks. The indexer,
MCP adapter, OpenClaw MCP inventory, scheduler, and LaunchAgent all completed
their validation successfully.

The vault contains Markdown that is deliberately not represented by indexed
chunks. In particular, discovery exclusions, five templates with dynamic
Obsidian `{{date:...}}` expressions that are not valid YAML frontmatter, and
six game notes with no chunkable body content are expected conditions. Therefore
the number of Markdown files in the mirror is not an appropriate equality check
for the number of manifest documents.

## Decision

1. Use `obsidian_chunks_v2` as the live Qdrant collection for the
   `personal-knowledge` Obsidian retrieval workload.
2. Use `data/obsidian/manifests-v2` as the live manifest root. The production
   manifest is `data/obsidian/manifests-v2/personal-knowledge.json`.
3. Update the Obsidian MCP configuration, indexer scheduler, operational
   checks, platform adapter, and OpenClaw Obsidian plugin to reference V2.
4. Treat a reconciliation as successful when:
   - the manifest vault ID matches the configured vault ID; and
   - the set of chunk IDs recorded in the manifest exactly equals the set of
     Qdrant point IDs for that vault and collection.

   Mirror Markdown counts must be reported as operational information only;
   they must not be asserted equal to manifest-document counts.
5. Retain `obsidian_chunks_v1` and its original manifest unchanged as the
   rollback target for at least 30 days after this accepted cutover. Do not
   delete V1 during that period. After the retention period, remove it only
   through a separately recorded cleanup decision after confirming V2 remains
   healthy and recoverable.

## Consequences

### Positive

- Production retrieval uses the independently rebuilt and accepted V2 index.
- The active scheduler explicitly uses the V2 manifest root, avoiding accidental
  writes to the V1 manifest.
- The validation check reflects the actual indexing contract and does not fail
  on intentional exclusions or zero-chunk notes.
- V1 remains available for a fast rollback without reindexing during the
  retention period.

### Trade-offs

- Two collections and two manifest roots consume storage during rollback
  retention.
- The six zero-chunk notes are rediscovered on incremental runs because they do
  not enter the manifest; this produces no embeddings, Qdrant writes, or
  retrieval data.
- Dynamic-template frontmatter remains excluded until the parser or template
  format is intentionally changed.

## Acceptance Evidence

The V2 cutover was accepted with the following observed results:

| Check | Result |
| --- | --- |
| Live collection | `obsidian_chunks_v2` |
| Live vault | `personal-knowledge` |
| Manifest documents | 39 |
| Qdrant chunks | 265 |
| Scheduler incremental run | 0 points upserted; 0 points deleted |
| LaunchAgent | Loaded; last exit code 0 |
| MCP adapter | Loaded with `obsidian_chunks_v2` |
| OpenClaw MCP doctor | `obsidian-retrieval: ok`; `platform-status: ok` |
| Reconciliation | Manifest chunk IDs exactly matched Qdrant IDs |

The mirror contained 1,702 Markdown files. The reported difference of 1,663
from the 39 manifest documents is expected: 1,657 discovery exclusions, five
invalid dynamic templates, and six zero-chunk game notes.

## Rollback

If a V2 retrieval, indexing, or operational defect requires rollback during the
retention period:

1. Restore the saved pre-cutover runtime configuration from the cutover backup.
2. Repoint the active configuration, scheduler, MCP adapter, and plugin to
   `obsidian_chunks_v1` and the original `data/obsidian/manifests` root.
3. Rebuild the OpenClaw Obsidian plugin if its compiled output changed.
4. Run the scheduler, `check-obsidian.sh`, the MCP adapter collection check,
   and `openclaw mcp doctor` before declaring rollback complete.

The V1 collection and its original manifest must not be modified as part of a
rollback; they are retained specifically as the known-good recovery target.

