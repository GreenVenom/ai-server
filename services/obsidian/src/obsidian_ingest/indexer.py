#!/usr/bin/env python3

"""Full Obsidian indexing pipeline with durable manifest output."""

from __future__ import annotations

import argparse
import json
import sys
from dataclasses import asdict, dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterable

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
    build_document_record,
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
    upsert_points,
    validate_collection,
)


PAYLOAD_SCHEMA_VERSION = 2
SOURCE_TYPE = "obsidian"
DEFAULT_MANIFEST_ROOT = Path.home() / "server/data/obsidian/manifests"


@dataclass(frozen=True)
class IndexReport:
    vault_id: str
    collection: str
    files_discovered: int
    files_included: int
    files_excluded: int
    documents_with_issues: int
    chunks_created: int
    points_upserted: int
    collection_point_count: int
    embedding_model: str
    embedding_dimension: int
    chunking_profile: str
    indexed_at: str
    manifest_path: str
    manifest_document_count: int


def _utc_now() -> str:
    return datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")


def _source_id(
    vault_id: str,
    relative_path: str,
) -> str:
    return f"{vault_id}:{relative_path}"


def _modified_at(path: Path) -> str:
    timestamp = path.stat().st_mtime

    return (
        datetime.fromtimestamp(
            timestamp,
            timezone.utc,
        )
        .isoformat()
        .replace("+00:00", "Z")
    )


def _document_payload(
    document: ParsedDocument,
    *,
    source_path: Path,
    vault_id: str,
    chunk: Any,
    indexed_at: str,
    metadata_hash: str,
) -> dict[str, Any]:
    return {
        "schema_version": PAYLOAD_SCHEMA_VERSION,
        "source_type": SOURCE_TYPE,
        "vault_id": vault_id,
        "source_id": _source_id(
            vault_id,
            document.relative_path,
        ),
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
        "metadata_hash": metadata_hash,
        "source_modified_at": _modified_at(source_path),
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


def full_index(
    root: Path,
    *,
    vault_id: str,
    collection: str = DEFAULT_COLLECTION,
    manifest_root: Path = DEFAULT_MANIFEST_ROOT,
    config: ChunkingConfig = ChunkingConfig(),
) -> IndexReport:
    root = root.expanduser().resolve()
    manifest_root = manifest_root.expanduser()

    validate_collection(collection)

    discovery = discover_markdown(root)

    included_documents: list[tuple[ParsedDocument, Path]] = []
    files_excluded = 0
    documents_with_issues = 0

    for item in discovery.discovered:
        source_path = Path(item.absolute_path)

        document = parse_document(
            source_path,
            root=root,
        )

        if document.issues:
            documents_with_issues += 1

        if document.should_index:
            included_documents.append(
                (document, source_path)
            )
        else:
            files_excluded += 1

    indexed_at = _utc_now()

    chunks_with_documents: list[
        tuple[ParsedDocument, Path, str, Any]
    ] = []

    manifest_documents = {}

    for document, source_path in included_documents:
        metadata_hash = document_metadata_hash(document)

        chunks = chunk_document(
            document,
            vault_id=vault_id,
            config=config,
        )

        for chunk in chunks:
            chunks_with_documents.append(
                (
                    document,
                    source_path,
                    metadata_hash,
                    chunk,
                )
            )

        if chunks:
            manifest_documents[document.relative_path] = (
                build_document_record(
                    relative_path=document.relative_path,
                    document_id=chunks[0].document_id,
                    source_hash=document.source_hash,
                    metadata_hash=metadata_hash,
                    source_modified_at=_modified_at(source_path),
                    chunk_ids=[
                        chunk.chunk_id
                        for chunk in chunks
                    ],
                    chunk_hashes=[
                        chunk.content_hash
                        for chunk in chunks
                    ],
                    indexed_at=indexed_at,
                )
            )

    points: list[dict[str, Any]] = []

    if chunks_with_documents:
        embedding_result = generate_embeddings(
            [
                chunk.embedding_text
                for _, _, _, chunk in chunks_with_documents
            ]
        )

        for index, item in enumerate(chunks_with_documents):
            document, source_path, metadata_hash, chunk = item

            points.append(
                {
                    "id": chunk.chunk_id,
                    "vector": {
                        VECTOR_NAME: list(
                            embedding_result.vectors[index]
                        )
                    },
                    "payload": _document_payload(
                        document,
                        source_path=source_path,
                        vault_id=vault_id,
                        chunk=chunk,
                        indexed_at=indexed_at,
                        metadata_hash=metadata_hash,
                    ),
                }
            )

        upsert_points(
            points,
            collection=collection,
        )

        embedding_model = embedding_result.model
        embedding_dimension = embedding_result.dimension
    else:
        embedding_model = DEFAULT_MODEL
        embedding_dimension = EXPECTED_DIMENSION

    output_manifest_path = manifest_path(
        manifest_root,
        vault_id,
    )

    manifest = IndexManifest(
        schema_version=1,
        vault_id=vault_id,
        collection=collection,
        embedding_model=embedding_model,
        embedding_dimension=embedding_dimension,
        chunking_profile=CHUNKING_PROFILE,
        generated_at=indexed_at,
        documents=manifest_documents,
    )

    write_manifest_atomic(
        output_manifest_path,
        manifest,
    )

    return IndexReport(
        vault_id=vault_id,
        collection=collection,
        files_discovered=len(discovery.discovered),
        files_included=len(included_documents),
        files_excluded=files_excluded,
        documents_with_issues=documents_with_issues,
        chunks_created=len(chunks_with_documents),
        points_upserted=len(points),
        collection_point_count=count_points(collection),
        embedding_model=embedding_model,
        embedding_dimension=embedding_dimension,
        chunking_profile=CHUNKING_PROFILE,
        indexed_at=indexed_at,
        manifest_path=str(output_manifest_path),
        manifest_document_count=len(manifest_documents),
    )


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Index an Obsidian vault or fixture into Qdrant."
    )

    parser.add_argument(
        "root",
        type=Path,
        help="Approved vault or fixture root.",
    )

    parser.add_argument(
        "--vault-id",
        required=True,
        help="Stable configured vault identifier.",
    )

    parser.add_argument(
        "--collection",
        default=DEFAULT_COLLECTION,
        help="Qdrant collection name.",
    )

    parser.add_argument(
        "--manifest-root",
        type=Path,
        default=DEFAULT_MANIFEST_ROOT,
        help="Directory used for durable index manifests.",
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
        report = full_index(
            args.root,
            vault_id=args.vault_id,
            collection=args.collection,
            manifest_root=args.manifest_root,
        )
    except Exception as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1

    if args.format == "json":
        print(
            json.dumps(
                asdict(report),
                indent=2,
                sort_keys=True,
            )
        )
    else:
        for key, value in asdict(report).items():
            print(f"{key}={value}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())