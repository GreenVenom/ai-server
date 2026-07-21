"""Shared MCP response envelope helpers."""

from __future__ import annotations

from typing import Any
from uuid import uuid4

from personal_ai_mcp.common.errors import MCPServiceError, ToolError


SCHEMA_VERSION = 1


def success_response(
    data: Any,
    *,
    request_id: str | None = None,
) -> dict[str, Any]:
    """Build a stable successful tool response."""
    return {
        "schema_version": SCHEMA_VERSION,
        "status": "success",
        "request_id": request_id or str(uuid4()),
        "data": data,
        "error": None,
    }


def error_response(
    error: MCPServiceError,
    *,
    request_id: str | None = None,
) -> dict[str, Any]:
    """Build a safe stable error response."""
    resolved_request_id = request_id or str(uuid4())

    tool_error = ToolError(
        code=error.code,
        message=error.safe_message,
        retryable=error.retryable,
        request_id=resolved_request_id,
    )

    return {
        "schema_version": SCHEMA_VERSION,
        "status": "error",
        "request_id": resolved_request_id,
        "data": None,
        "error": tool_error.as_dict(),
    }