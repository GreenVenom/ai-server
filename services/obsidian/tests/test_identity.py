from __future__ import annotations

import uuid

import obsidian_ingest.identity as identity


def _resolve(names: tuple[str, ...]):
    for name in names:
        candidate = getattr(identity, name, None)
        if callable(candidate):
            return candidate
    raise AssertionError(f"Missing identity callable; tried: {', '.join(names)}")


def test_document_identity_is_deterministic_and_path_sensitive() -> None:
    make_document_id = _resolve(
        ("document_id", "make_document_id", "build_document_id")
    )

    first = str(make_document_id("m05-fixture", "Notes/One.md"))
    second = str(make_document_id("m05-fixture", "Notes/One.md"))
    different = str(make_document_id("m05-fixture", "Notes/Two.md"))

    assert first == second
    assert first != different
    uuid.UUID(first)


def test_chunk_identity_is_deterministic_and_key_sensitive() -> None:
    make_chunk_id = _resolve(("chunk_id", "make_chunk_id", "build_chunk_id"))

    first = str(make_chunk_id("document-id", "heading-aware-v1|Title|0"))
    second = str(make_chunk_id("document-id", "heading-aware-v1|Title|0"))
    different = str(make_chunk_id("document-id", "heading-aware-v1|Title|1"))

    assert first == second
    assert first != different
    uuid.UUID(first)
