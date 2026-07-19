#!/usr/bin/env python3

"""Persistent indexing manifest for incremental Obsidian synchronization."""

from __future__ import annotations

import json
import os
import tempfile
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Any, Mapping, Sequence


MANIFEST_SCHEMA_VERSION = 1


class ManifestError(RuntimeError):
    """Raised when manifest state cannot be read or written safely."""


@dataclass(frozen=True)
class ManifestDocument:
    relative_path: str
    document_id: str
    source_hash: str
    metadata_hash: str
    source_modified_at: str
    chunk_ids: tuple[str, ...]
    chunk_hashes: tuple[str, ...]
    indexed_at: str


@dataclass(frozen=True)
class IndexManifest:
    schema_version: int
    vault_id: str
    collection: str
    embedding_model: str
    embedding_dimension: int
    chunking_profile: str
    generated_at: str
    documents: Mapping[str, ManifestDocument]


def manifest_path(
    manifest_root: Path,
    vault_id: str,
) -> Path:
    safe_vault_id = vault_id.replace("/", "_").replace("\\", "_")

    return manifest_root / f"{safe_vault_id}.json"


def empty_manifest(
    *,
    vault_id: str,
    collection: str,
    embedding_model: str,
    embedding_dimension: int,
    chunking_profile: str,
    generated_at: str,
) -> IndexManifest:
    return IndexManifest(
        schema_version=MANIFEST_SCHEMA_VERSION,
        vault_id=vault_id,
        collection=collection,
        embedding_model=embedding_model,
        embedding_dimension=embedding_dimension,
        chunking_profile=chunking_profile,
        generated_at=generated_at,
        documents={},
    )


def _document_from_mapping(
    relative_path: str,
    value: Mapping[str, Any],
) -> ManifestDocument:
    return ManifestDocument(
        relative_path=relative_path,
        document_id=str(value["document_id"]),
        source_hash=str(value["source_hash"]),
        metadata_hash=str(value.get("metadata_hash", "")),
        source_modified_at=str(value.get("source_modified_at", "")),
        chunk_ids=tuple(str(item) for item in value.get("chunk_ids", [])),
        chunk_hashes=tuple(
            str(item) for item in value.get("chunk_hashes", [])
        ),
        indexed_at=str(value["indexed_at"]),
    )


def load_manifest(
    path: Path,
    *,
    required: bool = False,
) -> IndexManifest | None:
    path = path.expanduser()

    if not path.exists():
        if required:
            raise ManifestError(f"Manifest does not exist: {path}")

        return None

    if not path.is_file():
        raise ManifestError(f"Manifest path is not a file: {path}")

    try:
        with path.open("r", encoding="utf-8") as handle:
            data = json.load(handle)
    except (OSError, json.JSONDecodeError) as exc:
        raise ManifestError(
            f"Unable to read manifest {path}: {exc}"
        ) from exc

    schema_version = data.get("schema_version")

    if schema_version != MANIFEST_SCHEMA_VERSION:
        raise ManifestError(
            "Unsupported manifest schema: "
            f"expected={MANIFEST_SCHEMA_VERSION}, "
            f"actual={schema_version}"
        )

    raw_documents = data.get("documents", {})

    if not isinstance(raw_documents, Mapping):
        raise ManifestError("Manifest documents must be an object")

    documents = {
        str(relative_path): _document_from_mapping(
            str(relative_path),
            value,
        )
        for relative_path, value in raw_documents.items()
    }

    return IndexManifest(
        schema_version=schema_version,
        vault_id=str(data["vault_id"]),
        collection=str(data["collection"]),
        embedding_model=str(data["embedding_model"]),
        embedding_dimension=int(data["embedding_dimension"]),
        chunking_profile=str(data["chunking_profile"]),
        generated_at=str(data["generated_at"]),
        documents=documents,
    )


def _serialize_manifest(
    manifest: IndexManifest,
) -> dict[str, Any]:
    documents = {
        relative_path: asdict(document)
        for relative_path, document in sorted(
            manifest.documents.items()
        )
    }

    return {
        "schema_version": manifest.schema_version,
        "vault_id": manifest.vault_id,
        "collection": manifest.collection,
        "embedding_model": manifest.embedding_model,
        "embedding_dimension": manifest.embedding_dimension,
        "chunking_profile": manifest.chunking_profile,
        "generated_at": manifest.generated_at,
        "documents": documents,
    }


def write_manifest_atomic(
    path: Path,
    manifest: IndexManifest,
) -> None:
    path = path.expanduser()
    path.parent.mkdir(parents=True, exist_ok=True)

    payload = json.dumps(
        _serialize_manifest(manifest),
        indent=2,
        sort_keys=True,
    )

    temporary_path: Path | None = None

    try:
        with tempfile.NamedTemporaryFile(
            mode="w",
            encoding="utf-8",
            dir=str(path.parent),
            prefix=f".{path.name}.",
            suffix=".tmp",
            delete=False,
        ) as handle:
            temporary_path = Path(handle.name)
            handle.write(payload)
            handle.write("\n")
            handle.flush()
            os.fsync(handle.fileno())

        os.chmod(temporary_path, 0o600)
        os.replace(temporary_path, path)
    except OSError as exc:
        if temporary_path is not None:
            temporary_path.unlink(missing_ok=True)

        raise ManifestError(
            f"Unable to write manifest {path}: {exc}"
        ) from exc


def build_document_record(
    *,
    relative_path: str,
    document_id: str,
    source_hash: str,
    metadata_hash: str,
    source_modified_at: str,
    chunk_ids: Sequence[str],
    chunk_hashes: Sequence[str],
    indexed_at: str,
) -> ManifestDocument:
    return ManifestDocument(
        relative_path=relative_path,
        document_id=document_id,
        source_hash=source_hash,
        metadata_hash=metadata_hash,
        source_modified_at=source_modified_at,
        chunk_ids=tuple(chunk_ids),
        chunk_hashes=tuple(chunk_hashes),
        indexed_at=indexed_at,
    )