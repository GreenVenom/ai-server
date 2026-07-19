#!/usr/bin/env python3

"""Incremental Obsidian indexing and reconciliation."""

from __future__ import annotations

import argparse
import json
import sys
from dataclasses import asdict, dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterable, Mapping

from obsidian_ingest.chunking import (
    CHUNKING_PROFILE,
    ChunkingConfig,
    chunk_document,
)
from obsidian_ingest.discovery import discover_markdown
from obsidian_ingest.embeddings import (
    DEFAULT_MODEL,
    EXPECTED_DIMENSION,
    generate_embeddings,
)
from obsidian_ingest.manifest import (
    IndexManifest,
    ManifestDocument,
    build_document_record,
    load_manifest,
    manifest_path,
    write_manifest_atomic,
)
from obsidian_ingest.parser import (
    ParsedDocument,
    document_metadata_hash,
    parse_document,
)
from obsidian_ingest.qdrant import (
    DEFAULT_COLLECTION,
    VECTOR_NAME,
    count_points,
    delete_points,
    upsert_points,
    validate_collection,
)


DEFAULT_MANIFEST_ROOT = Path.home() / "server/data/obsidian/manifests"
PAYLOAD_SCHEMA_VERSION = 2
SOURCE_TYPE = "obsidian"


@dataclass(frozen=True)
class DocumentState:
    document: ParsedDocument
    source_path: Path
    metadata_hash: str
    chunks: tuple[Any, ...]
    source_modified_at: str


@dataclass(frozen=True)
class ChangeSet:
    added: tuple[str, ...]
    source_changed: tuple[str, ...]
    metadata_changed: tuple[str, ...]
    unchanged: tuple[str, ...]
    excluded: tuple[str, ...]
    deleted: tuple[str, ...]
    parse_errors: tuple[str, ...]


@dataclass(frozen=True)
class IncrementalReport:
    vault_id: str
    collection: str
    files_discovered: int
    added: int
    source_changed: int
    metadata_changed: int
    unchanged: int
    excluded: int
    deleted: int
    parse_errors: int
    documents_reindexed: int
    chunks_embedded: int
    points_upserted: int
    points_deleted: int
    collection_point_count: int
    manifest_document_count: int
    indexed_at: str


class IncrementalError(RuntimeError):
    """Raised when incremental reconciliation cannot proceed safely."""


def _utc_now() -> str:
    return datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")


def _modified_at(path: Path) -> str:
    timestamp = path.stat().st_mtime

    return (
        datetime.fromtimestamp(timestamp, timezone.utc)
        .isoformat()
        .replace("+00:00", "Z")
    )


def _source_id(vault_id: str, relative_path: str) -> str:
    return f"{vault_id}:{relative_path}"


def _payload(
    state: DocumentState,
    *,
    vault_id: str,
    chunk: Any,
    indexed_at: str,
) -> dict[str, Any]:
    document = state.document

    return {
        "schema_version": PAYLOAD_SCHEMA_VERSION,
        "source_type": SOURCE_TYPE,
        "vault_id": vault_id,
        "source_id": _source_id(vault_id, document.relative_path),
        "document_id": chunk.document_id,
        "chunk_id": chunk.chunk_id,
        "chunk_key": chunk.chunk_key,
        "title": document.title,
        "relative_path": document.relative_path,
        "file_name": Path(document.relative_path).name,
        "file_extension": ".md",
        "heading": chunk.heading,
        "heading_path": list(chunk.heading_path),
        "heading_level": chunk.heading_level,
        "chunk_index": chunk.chunk_index,
        "chunk_count": chunk.chunk_count,
        "chunk_text": chunk.chunk_text,
        "embedding_text": chunk.embedding_text,
        "content_hash": chunk.content_hash,
        "source_hash": document.source_hash,
        "metadata_hash": state.metadata_hash,
        "source_modified_at": state.source_modified_at,
        "indexed_at": indexed_at,
        "embedding_model": DEFAULT_MODEL,
        "embedding_dimension": EXPECTED_DIMENSION,
        "tags": list(document.tags),
        "aliases": list(document.aliases),
        "wikilinks": [
            {
                "target": link.target,
                "heading": link.heading,
                "label": link.label,
                "embedded": link.embedded,
            }
            for link in document.wikilinks
        ],
        "markdown_links": [
            {
                "label": link.label,
                "target": link.target,
            }
            for link in document.markdown_links
        ],
        "visibility": str(
            document.frontmatter.get("visibility", "private")
        ),
        "index_profile": CHUNKING_PROFILE,
    }


def discover_states(
    root: Path,
    *,
    vault_id: str,
    config: ChunkingConfig,
) -> tuple[Mapping[str, DocumentState], tuple[str, ...], tuple[str, ...], int]:
    discovery = discover_markdown(root)

    states: dict[str, DocumentState] = {}
    excluded: list[str] = []
    parse_errors: list[str] = []

    for item in discovery.discovered:
        source_path = Path(item.absolute_path)
        document = parse_document(source_path, root=root)

        if document.issues:
            parse_errors.append(document.relative_path)

        if not document.should_index:
            excluded.append(document.relative_path)
            continue

        chunks = chunk_document(
            document,
            vault_id=vault_id,
            config=config,
        )

        states[document.relative_path] = DocumentState(
            document=document,
            source_path=source_path,
            metadata_hash=document_metadata_hash(document),
            chunks=chunks,
            source_modified_at=_modified_at(source_path),
        )

    return (
        states,
        tuple(sorted(excluded)),
        tuple(sorted(parse_errors)),
        len(discovery.discovered),
    )


def classify_changes(
    current: Mapping[str, DocumentState],
    previous: IndexManifest,
    *,
    excluded_paths: tuple[str, ...],
    parse_error_paths: tuple[str, ...],
) -> ChangeSet:
    added: list[str] = []
    source_changed: list[str] = []
    metadata_changed: list[str] = []
    unchanged: list[str] = []

    for relative_path, state in current.items():
        old = previous.documents.get(relative_path)

        if old is None:
            added.append(relative_path)
            continue

        current_chunk_hashes = tuple(
            chunk.content_hash
            for chunk in state.chunks
        )

        if current_chunk_hashes != old.chunk_hashes:
            source_changed.append(relative_path)
            continue

        if state.metadata_hash != old.metadata_hash:
            metadata_changed.append(relative_path)
            continue

        unchanged.append(relative_path)

    current_paths = set(current)
    excluded_set = set(excluded_paths)
    parse_error_set = set(parse_error_paths)

    deleted = sorted(
        path
        for path in previous.documents
        if (
            path not in current_paths
            and path not in excluded_set
            and path not in parse_error_set
        )
    )

    return ChangeSet(
        added=tuple(sorted(added)),
        source_changed=tuple(sorted(source_changed)),
        metadata_changed=tuple(sorted(metadata_changed)),
        unchanged=tuple(sorted(unchanged)),
        excluded=tuple(sorted(excluded_paths)),
        deleted=tuple(deleted),
        parse_errors=tuple(sorted(parse_error_paths)),
    )


def incremental_index(
    root: Path,
    *,
    vault_id: str,
    collection: str = DEFAULT_COLLECTION,
    manifest_root: Path = DEFAULT_MANIFEST_ROOT,
    config: ChunkingConfig = ChunkingConfig(),
    maximum_delete_percent: float = 10.0,
    allow_large_delete: bool = False,
) -> IncrementalReport:
    root = root.expanduser().resolve()
    validate_collection(collection)

    path = manifest_path(manifest_root, vault_id)
    previous = load_manifest(path, required=True)

    if previous.vault_id != vault_id:
        raise IncrementalError("Manifest vault ID does not match request")

    if previous.collection != collection:
        raise IncrementalError("Manifest collection does not match request")

    current, excluded, parse_errors, files_discovered = discover_states(
        root,
        vault_id=vault_id,
        config=config,
    )

    changes = classify_changes(
        current,
        previous,
        excluded_paths=excluded,
        parse_error_paths=parse_errors,
    )

    deletion_candidates = set(changes.deleted)

    for path_name in changes.excluded:
        if path_name in previous.documents:
            deletion_candidates.add(path_name)

    previous_count = len(previous.documents)

    deletion_percent = (
        (len(deletion_candidates) / previous_count) * 100.0
        if previous_count
        else 0.0
    )

    if (
        deletion_percent > maximum_delete_percent
        and not allow_large_delete
    ):
        raise IncrementalError(
            "Deletion threshold exceeded: "
            f"proposed={deletion_percent:.2f}%, "
            f"maximum={maximum_delete_percent:.2f}%"
        )

    indexed_at = _utc_now()

    reindex_paths = set(changes.added)
    reindex_paths.update(changes.source_changed)
    reindex_paths.update(changes.metadata_changed)

    chunks_to_embed: list[tuple[DocumentState, Any]] = []

    for relative_path in sorted(reindex_paths):
        state = current[relative_path]

        for chunk in state.chunks:
            chunks_to_embed.append((state, chunk))

    points: list[dict[str, Any]] = []

    if chunks_to_embed:
        embedding_result = generate_embeddings(
            [
                chunk.embedding_text
                for _, chunk in chunks_to_embed
            ]
        )

        for index, (state, chunk) in enumerate(chunks_to_embed):
            points.append(
                {
                    "id": chunk.chunk_id,
                    "vector": {
                        VECTOR_NAME: list(
                            embedding_result.vectors[index]
                        )
                    },
                    "payload": _payload(
                        state,
                        vault_id=vault_id,
                        chunk=chunk,
                        indexed_at=indexed_at,
                    ),
                }
            )

        upsert_points(points, collection=collection)

    stale_chunk_ids: set[str] = set()

    for relative_path in sorted(
        set(changes.source_changed)
        | set(changes.metadata_changed)
        | deletion_candidates
    ):
        old = previous.documents.get(relative_path)

        if old is None:
            continue

        replacement_ids = {
            chunk.chunk_id
            for chunk in current.get(
                relative_path,
                DocumentState(
                    document=None,       # type: ignore[arg-type]
                    source_path=Path(),
                    metadata_hash="",
                    chunks=(),
                    source_modified_at="",
                ),
            ).chunks
        }

        stale_chunk_ids.update(
            set(old.chunk_ids) - replacement_ids
        )

    if stale_chunk_ids:
        delete_points(
            sorted(stale_chunk_ids),
            collection=collection,
        )

    new_documents: dict[str, ManifestDocument] = {}

    for relative_path, old in previous.documents.items():
        if relative_path in deletion_candidates:
            continue

        if relative_path in current:
            continue

        new_documents[relative_path] = old

    for relative_path, state in current.items():
        if relative_path in changes.unchanged:
            new_documents[relative_path] = previous.documents[relative_path]
            continue

        if not state.chunks:
            continue

        new_documents[relative_path] = build_document_record(
            relative_path=relative_path,
            document_id=state.chunks[0].document_id,
            source_hash=state.document.source_hash,
            metadata_hash=state.metadata_hash,
            source_modified_at=state.source_modified_at,
            chunk_ids=[
                chunk.chunk_id
                for chunk in state.chunks
            ],
            chunk_hashes=[
                chunk.content_hash
                for chunk in state.chunks
            ],
            indexed_at=indexed_at,
        )

    manifest = IndexManifest(
        schema_version=1,
        vault_id=vault_id,
        collection=collection,
        embedding_model=DEFAULT_MODEL,
        embedding_dimension=EXPECTED_DIMENSION,
        chunking_profile=CHUNKING_PROFILE,
        generated_at=indexed_at,
        documents=new_documents,
    )

    write_manifest_atomic(path, manifest)

    return IncrementalReport(
        vault_id=vault_id,
        collection=collection,
        files_discovered=files_discovered,
        added=len(changes.added),
        source_changed=len(changes.source_changed),
        metadata_changed=len(changes.metadata_changed),
        unchanged=len(changes.unchanged),
        excluded=len(changes.excluded),
        deleted=len(changes.deleted),
        parse_errors=len(changes.parse_errors),
        documents_reindexed=len(reindex_paths),
        chunks_embedded=len(chunks_to_embed),
        points_upserted=len(points),
        points_deleted=len(stale_chunk_ids),
        collection_point_count=count_points(collection),
        manifest_document_count=len(new_documents),
        indexed_at=indexed_at,
    )


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Incrementally reconcile Obsidian content."
    )

    parser.add_argument("root", type=Path)
    parser.add_argument("--vault-id", required=True)
    parser.add_argument("--collection", default=DEFAULT_COLLECTION)
    parser.add_argument(
        "--manifest-root",
        type=Path,
        default=DEFAULT_MANIFEST_ROOT,
    )
    parser.add_argument(
        "--maximum-delete-percent",
        type=float,
        default=10.0,
    )
    parser.add_argument(
        "--allow-large-delete",
        action="store_true",
    )
    parser.add_argument(
        "--format",
        choices=("text", "json"),
        default="text",
    )

    return parser


def main(argv: Iterable[str] | None = None) -> int:
    args = build_parser().parse_args(argv)

    try:
        report = incremental_index(
            args.root,
            vault_id=args.vault_id,
            collection=args.collection,
            manifest_root=args.manifest_root,
            maximum_delete_percent=args.maximum_delete_percent,
            allow_large_delete=args.allow_large_delete,
        )
    except Exception as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1

    if args.format == "json":
        print(json.dumps(asdict(report), indent=2, sort_keys=True))
    else:
        for key, value in asdict(report).items():
            print(f"{key}={value}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())