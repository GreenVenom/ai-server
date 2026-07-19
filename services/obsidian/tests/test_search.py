from __future__ import annotations

from types import SimpleNamespace

import obsidian_ingest.search as search


def test_semantic_search_builds_vault_tag_and_path_filters(monkeypatch) -> None:
    captured = {}

    monkeypatch.setattr(search, "embed_text", lambda query: (0.0,) * 768)

    def fake_query_points(vector, **kwargs):
        captured.update(kwargs)
        return (
            {
                "id": "chunk-1",
                "score": 0.91,
                "payload": {
                    "document_id": "doc-1",
                    "chunk_id": "chunk-1",
                    "title": "Qdrant Operations",
                    "relative_path": "nested/Qdrant Operations.md",
                    "heading": "Deployment",
                    "chunk_text": "Qdrant runs through Docker Compose.",
                    "tags": ["qdrant"],
                },
            },
        )

    monkeypatch.setattr(search, "query_points", fake_query_points)

    results = search.semantic_search(
        "How is Qdrant deployed?",
        collection="obsidian_chunks_v1",
        vault_id="m05-fixture",
        tag="qdrant",
        relative_path="nested/Qdrant Operations.md",
        limit=3,
        score_threshold=0.35,
    )

    assert len(results) == 1
    assert results[0].relative_path == "nested/Qdrant Operations.md"
    assert captured["collection"] == "obsidian_chunks_v1"
    assert captured["limit"] == 3
    assert captured["score_threshold"] == 0.35
    assert captured["query_filter"]["must"]


def test_search_cli_rejects_nonpositive_limit() -> None:
    parser = search.build_parser()
    args = parser.parse_args(["query", "--limit", "0"])
    assert args.limit == 0
