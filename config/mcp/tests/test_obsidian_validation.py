"""Security and validation tests for Obsidian MCP requests."""

from __future__ import annotations

import pytest
from pydantic import ValidationError

from personal_ai_mcp.obsidian.schemas import SearchRequest


def valid_request(**overrides: object) -> dict[str, object]:
    request: dict[str, object] = {
        "query": "How does Qdrant backup work?",
        "vault_id": "personal-knowledge",
    }
    request.update(overrides)
    return request


@pytest.mark.parametrize(
    "path",
    [
        "/Users/openclaw/.ssh",
        "~/server/config",
        "../../.ssh",
        "Projects/../../.ssh",
        "file:///etc/passwd",
        r"C:\Users\Administrator",
        "Projects//Secrets",
    ],
)
def test_rejects_unsafe_paths(path: str) -> None:
    with pytest.raises(ValidationError):
        SearchRequest.model_validate(
            valid_request(relative_path=path)
        )


@pytest.mark.parametrize(
    "path",
    [
        "Projects/M04 Deployment.md",
        "Projects/AI Server/Qdrant Operations.md",
        "D&D/Campaign Notes/Session 5.md",
    ],
)
def test_accepts_relative_paths(path: str) -> None:
    request = SearchRequest.model_validate(
        valid_request(relative_path=path)
    )

    assert request.relative_path == path


def test_rejects_unknown_fields() -> None:
    with pytest.raises(ValidationError):
        SearchRequest.model_validate(
            valid_request(collection="m04_validation")
        )


def test_rejects_excessive_limit() -> None:
    with pytest.raises(ValidationError):
        SearchRequest.model_validate(
            valid_request(limit=9)
        )


def test_accepts_maximum_limit() -> None:
    request = SearchRequest.model_validate(
        valid_request(limit=8)
    )

    assert request.limit == 8


def test_rejects_oversized_query() -> None:
    with pytest.raises(ValidationError):
        SearchRequest.model_validate(
            valid_request(query="x" * 501)
        )


def test_accepts_maximum_query_length() -> None:
    request = SearchRequest.model_validate(
        valid_request(query="x" * 500)
    )

    assert len(request.query) == 500


def test_normalizes_tag() -> None:
    request = SearchRequest.model_validate(
        valid_request(tag="#Qdrant")
    )

    assert request.tag == "qdrant"


def test_rejects_multiple_tags_field() -> None:
    with pytest.raises(ValidationError):
        SearchRequest.model_validate(
            valid_request(tags=["qdrant", "backup"])
        )