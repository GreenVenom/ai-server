"""Live tests for remaining Obsidian MCP tool implementations."""

from __future__ import annotations

import pytest

from personal_ai_mcp.obsidian.tools import (
    obsidian_get_chunk_tool,
    obsidian_list_vaults_tool,
    obsidian_retrieval_status_tool,
)


KNOWN_CHUNK_ID = "01e40465-a262-5861-b243-a7597ab2c573"


@pytest.mark.integration
def test_get_approved_chunk() -> None:
    response = obsidian_get_chunk_tool(
        vault_id="personal-knowledge",
        chunk_id=KNOWN_CHUNK_ID,
    )

    assert response["status"] == "success"
    assert response["error"] is None

    chunk = response["data"]["chunk"]

    assert chunk["chunk_id"] == KNOWN_CHUNK_ID
    assert chunk["relative_path"] == (
        "Passive Income Ideas/Implemented/HoneyGain.md"
    )
    assert len(chunk["chunk_text"]) <= 4_000


@pytest.mark.integration
def test_get_unknown_chunk_returns_not_found() -> None:
    response = obsidian_get_chunk_tool(
        vault_id="personal-knowledge",
        chunk_id="00000000-0000-0000-0000-000000000000",
    )

    assert response["status"] == "error"
    assert response["error"]["code"] == "MCP-NOT-FOUND"


@pytest.mark.integration
def test_list_vaults_exposes_only_safe_metadata() -> None:
    response = obsidian_list_vaults_tool()

    assert response["status"] == "success"
    assert response["data"]["vault_count"] == 1

    vault = response["data"]["vaults"][0]

    assert vault["vault_id"] == "personal-knowledge"
    assert vault["access"] == "read-only"
    assert "manifest" not in vault
    assert "path" not in vault


@pytest.mark.integration
def test_retrieval_status_is_reconciled() -> None:
    response = obsidian_retrieval_status_tool(
        vault_id="personal-knowledge"
    )

    assert response["status"] == "success"
    assert response["data"]["healthy"] is True

    vault = response["data"]["vaults"][0]

    assert vault["document_count"] == 7
    assert vault["manifest_chunk_count"] == 176
    assert vault["collection_point_count"] == 176
    assert vault["approved_vault_point_count"] == 176
    assert vault["missing_point_count"] == 0
    assert vault["orphan_point_count"] == 0
    assert vault["unapproved_vault_ids"] == []
    assert vault["reconciled"] is True