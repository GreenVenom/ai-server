from pathlib import Path

from obsidian_ingest.manifest import (
    IndexManifest,
    build_document_record,
    load_manifest,
    manifest_path,
    write_manifest_atomic,
)


def test_manifest_round_trip_and_permissions(tmp_path: Path) -> None:
    path = manifest_path(tmp_path, "m05-test")
    document = build_document_record(
        relative_path="Notes/Test.md",
        document_id="document-test",
        source_hash="source-hash",
        metadata_hash="metadata-hash",
        source_modified_at="2026-07-18T20:00:00Z",
        chunk_ids=("chunk-1", "chunk-2"),
        chunk_hashes=("hash-1", "hash-2"),
        indexed_at="2026-07-18T20:01:00Z",
    )
    manifest = IndexManifest(
        schema_version=1,
        vault_id="m05-test",
        collection="obsidian_chunks_v1",
        embedding_model="nomic-embed-text:latest",
        embedding_dimension=768,
        chunking_profile="heading-aware-v1",
        generated_at="2026-07-18T20:01:00Z",
        documents={document.relative_path: document},
    )

    write_manifest_atomic(path, manifest)
    loaded = load_manifest(path, required=True)

    assert loaded == manifest
    assert path.stat().st_mode & 0o777 == 0o600


def test_missing_optional_manifest_returns_empty_or_none(tmp_path: Path) -> None:
    path = tmp_path / "missing.json"
    loaded = load_manifest(path, required=False)

    assert loaded is None or not loaded.documents
