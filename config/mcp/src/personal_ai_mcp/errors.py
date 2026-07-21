"""Stable error types and envelopes for MCP tools."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any
from uuid import uuid4


@dataclass(frozen=True, slots=True)
class ToolError:
    """Safe error returned to an MCP client."""

    code: str
    message: str
    retryable: bool = False
    request_id: str = ""

    def as_dict(self) -> dict[str, Any]:
        request_id = self.request_id or str(uuid4())

        return {
            "code": self.code,
            "message": self.message,
            "retryable": self.retryable,
            "request_id": request_id,
        }


class MCPServiceError(RuntimeError):
    """Base exception for controlled MCP service failures."""

    code = "MCP-INTERNAL"
    retryable = False

    def __init__(self, message: str) -> None:
        super().__init__(message)
        self.safe_message = message


class ValidationError(MCPServiceError):
    code = "MCP-VALIDATION"


class AuthorizationError(MCPServiceError):
    code = "MCP-AUTHORIZATION"


class DependencyError(MCPServiceError):
    code = "MCP-DEPENDENCY"
    retryable = True


class ToolTimeoutError(MCPServiceError):
    code = "MCP-TIMEOUT"
    retryable = True


class ObsidianRetrievalError(MCPServiceError):
    code = "MCP-OBS"