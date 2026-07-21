"""Tests for the subprocess-backed M05 retrieval adapter."""

from __future__ import annotations

import json
from subprocess import CompletedProcess
from unittest.mock import patch

import pytest

from personal_ai_mcp.common.errors import AuthorizationError
from personal_ai_mcp.obsidian.adapter import search
from personal_ai_mcp.obsidian.config import (
    ObsidianMCPConfig,
    RetrievalRuntime,
    VaultConfig,
)
from personal_ai_mcp.obsidian.schemas import SearchRequest


@pytest.fixture
def config() -> ObsidianMCPConfig:
    return ObsidianMCPConfig(
        runtime=RetrievalRuntime(
            executable="/approved/python",
            module="obsidian_ingest.retrieval_boundary",
            pythonpath="/approved/src",
            timeout_seconds=15,
        ),
        vaults={
            "personal-knowledge": VaultConfig(
                vault_id="personal-knowledge",
                collection="obsidian_chunks_v1",
            )
        },
    )


def test_uses_configured_collection_and_no_shell(
    config: ObsidianMCPConfig,
) -> None:
    response = {
        "schema_version": 1,
        "query": "Qdrant backup",
        "vault_id": "personal-knowledge",
        "collection": "obsidian_chunks_v1",
        "result_count": 0,
        "results": [],
    }

    with patch(
        "personal_ai_mcp.obsidian.adapter.subprocess.run",
        return_value=CompletedProcess(
            args=[],
            returncode=0,
            stdout=json.dumps(response),
            stderr="",
        ),
    ) as run:
        result = search(
            SearchRequest(
                query="Qdrant backup",
                vault_id="personal-knowledge",
            ),
            config=config,
        )

    assert result.payload["collection"] == "obsidian_chunks_v1"

    command = run.call_args.args[0]
    kwargs = run.call_args.kwargs

    assert command[0] == "/approved/python"
    assert "--collection" in command
    assert "obsidian_chunks_v1" in command
    assert kwargs.get("shell") is None


def test_unknown_vault_is_rejected(
    config: ObsidianMCPConfig,
) -> None:
    request = SearchRequest(
        query="Qdrant backup",
        vault_id="unapproved",
    )

    with pytest.raises(AuthorizationError):
        search(request, config=config)