"""Tool implementations for the Obsidian Retrieval MCP server."""

from __future__ import annotations

from typing import Any
from uuid import uuid4

from pydantic import ValidationError as PydanticValidationError

from personal_ai_mcp.common.errors import (
    MCPServiceError,
    ValidationError,
)
from personal_ai_mcp.common.models import (
    error_response,
    success_response,
)
from personal_ai_mcp.obsidian.adapter import search
from personal_ai_mcp.obsidian.schemas import SearchRequest


def obsidian_search_tool(
    *,
    query: str,
    vault_id: str,
    limit: int = 5,
    score_threshold: float | None = None,
    tag: str | None = None,
    relative_path: str | None = None,
) -> dict[str, Any]:
    """Execute one safe, read-only Obsidian semantic search."""
    request_id = str(uuid4())

    try:
        request = SearchRequest.model_validate(
            {
                "query": query,
                "vault_id": vault_id,
                "limit": limit,
                "score_threshold": score_threshold,
                "tag": tag,
                "relative_path": relative_path,
            }
        )

        execution = search(request)

        return success_response(
            execution.payload,
            request_id=request_id,
        )

    except PydanticValidationError:
        return error_response(
            ValidationError(
                "The Obsidian search request is invalid."
            ),
            request_id=request_id,
        )

    except MCPServiceError as exc:
        return error_response(
            exc,
            request_id=request_id,
        )

    except Exception:
        return error_response(
            MCPServiceError(
                "The Obsidian search request failed."
            ),
            request_id=request_id,
        )