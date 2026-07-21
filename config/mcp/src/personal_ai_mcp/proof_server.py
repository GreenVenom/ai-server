"""Minimal MCP protocol proof for M06."""

from __future__ import annotations

import platform
from typing import Any

from mcp.server.fastmcp import FastMCP

SERVER_NAME = "personal-ai-mcp-proof"
SERVER_VERSION = "0.1.0"

mcp = FastMCP(
    SERVER_NAME,
    json_response=True,
)


@mcp.tool()
def server_info() -> dict[str, Any]:
    """Return safe metadata about the M06 MCP protocol proof server."""
    return {
        "schema_version": 1,
        "server": SERVER_NAME,
        "version": SERVER_VERSION,
        "transport": "stdio",
        "access": "read-only",
        "python_version": platform.python_version(),
    }


if __name__ == "__main__":
    mcp.run(transport="stdio")