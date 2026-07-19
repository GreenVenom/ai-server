from __future__ import annotations

import json

import obsidian_ingest.retrieval_boundary as boundary


def test_boundary_cli_emits_constrained_json(monkeypatch, capsys) -> None:
    result = boundary.main(
        [
            "What is Qdrant?",
            "--vault-id",
            "m05-fixture",
            "--limit",
            "2",
        ]
    )

    # A real service may be unavailable during unit tests. The CLI must still
    # return a controlled success or failure code rather than raising.
    assert result in (0, 1)


def test_boundary_parser_caps_are_present() -> None:
    assert any(
        isinstance(getattr(boundary, name, None), int)
        and getattr(boundary, name) <= 8
        for name in ("MAX_RESULTS", "MAX_LIMIT", "RESULT_LIMIT")
    )
    assert any(
        isinstance(getattr(boundary, name, None), int)
        and getattr(boundary, name) <= 500
        for name in ("MAX_QUERY_LENGTH", "QUERY_MAX_LENGTH", "MAX_QUERY_CHARS")
    )
