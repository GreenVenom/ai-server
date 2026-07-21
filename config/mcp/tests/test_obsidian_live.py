"""Live integration test against the installed M05 retrieval service."""

from __future__ import annotations

import pytest

from personal_ai_mcp.obsidian.adapter import search
from personal_ai_mcp.obsidian.schemas import SearchRequest


@pytest.mark.integration
def test_live_obsidian_retrieval() -> None:
    execution = search(
        SearchRequest(
            query="Qdrant backup snapshot retention",
            vault_id="personal-knowledge",
            limit=3,
            score_threshold=0.30,
        )
    )

    payload = execution.payload

    assert payload["schema_version"] == 1
    assert payload["vault_id"] == "personal-knowledge"
    assert payload["collection"] == "obsidian_chunks_v1"
    assert 1 <= payload["result_count"] <= 3

    for result in payload["results"]:
        assert result["title"]
        assert result["relative_path"]
        assert result["document_id"]
        assert result["chunk_id"]
        assert isinstance(result["score"], float)
        assert len(result["chunk_text"]) <= 4_000
        assert not result["relative_path"].startswith("/")