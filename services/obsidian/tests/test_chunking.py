from __future__ import annotations

import inspect

import obsidian_ingest.chunking as chunking


def _chunk_callable():
    for name in ("chunk_document", "chunk_parsed_document", "build_chunks"):
        candidate = getattr(chunking, name, None)
        if callable(candidate):
            return candidate
    raise AssertionError(
        "No supported public chunking entry point found. "
        "Expected chunk_document, chunk_parsed_document, or build_chunks."
    )


def test_chunking_is_heading_aware_and_deterministic(parsed_platform) -> None:
    function = _chunk_callable()
    signature = inspect.signature(function)

    kwargs = {}
    if "document" in signature.parameters:
        kwargs["document"] = parsed_platform
        first = tuple(function(**kwargs))
        second = tuple(function(**kwargs))
    else:
        first = tuple(function(parsed_platform))
        second = tuple(function(parsed_platform))

    assert first
    assert first == second
    assert all(getattr(item, "chunk_id", None) for item in first)
    assert all(getattr(item, "content_hash", None) for item in first)
    assert any(
        "Runtime Components" in str(getattr(item, "heading_path", ""))
        for item in first
    )
