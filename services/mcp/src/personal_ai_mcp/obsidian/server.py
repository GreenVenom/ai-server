from mcp.server.fastmcp import FastMCP
from personal_ai_mcp.common.adapter import guarded
from .tools import (
    obsidian_search_tool,
    obsidian_get_chunk_tool,
    obsidian_list_vaults_tool,
    obsidian_retrieval_status_tool,
)

mcp = FastMCP("obsidian-retrieval")

@mcp.tool()
def obsidian_search(
    vault_id: str,
    query: str,
    limit: int = 5,
) -> dict:
    return guarded(
        lambda: obsidian_search_tool(vault_id, query, limit)
    )

@mcp.tool()
def obsidian_get_chunk(
    vault_id: str,
    chunk_id: str,
) -> dict:
    return guarded(
        lambda: obsidian_get_chunk_tool(vault_id, chunk_id)
    )

@mcp.tool()
def obsidian_list_vaults() -> dict:
    return guarded(obsidian_list_vaults_tool)

@mcp.tool()
def obsidian_retrieval_status(vault_id: str) -> dict:
    return guarded(
        lambda: obsidian_retrieval_status_tool(vault_id)
    )

if __name__ == "__main__":
    mcp.run(transport="stdio")
