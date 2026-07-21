from collections.abc import Callable
from typing import Any
from .errors import MCPServiceError
from .models import failure

def guarded(call: Callable[[], Any]) -> Any:
    try:
        return call()
    except MCPServiceError as exc:
        return failure(exc.code, exc.message, exc.retryable)
    except Exception:
        return failure(
            "MCP-INTERNAL",
            "The tool encountered an internal error.",
            False,
        )
