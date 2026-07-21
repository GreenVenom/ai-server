"""Read-only Obsidian Retrieval MCP server."""

from __future__ import annotations

from typing import Any

from mcp.server.fastmcp import FastMCP

from personal_ai_mcp.obsidian.tools import obsidian_search_tool


SERVER_NAME = "personal-ai-obsidian-retrieval"
SERVER_VERSION = "0.1.0"

mcp = FastMCP(
    SERVER_NAME,
    json_response=True,
)


@mcp.tool()
def obsidian_search(
    query: str,
    vault_id: str,
    limit: int = 5,
    score_threshold: float | None = None,
    tag: str | None = None,
    relative_path: str | None = None,
) -> dict[str, Any]:
    """Search approved indexed Obsidian content.

    This tool is read-only. It searches only configured vaults and cannot
    access arbitrary files, select Qdrant collections, or modify notes.
    The relative_path argument is an exact vault-relative path filter.
    """
    return obsidian_search_tool(
        query=query,
        vault_id=vault_id,
        limit=limit,
        score_threshold=score_threshold,
        tag=tag,
        relative_path=relative_path,
    )


if __name__ == "__main__":
    mcp.run(transport="stdio")