"""Protocol tests for the production Obsidian MCP server."""

from __future__ import annotations

import sys
from pathlib import Path

import pytest
from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client


PROJECT_ROOT = Path(__file__).resolve().parents[1]


@pytest.mark.asyncio
async def test_obsidian_server_exposes_exact_tool_set() -> None:
    server = StdioServerParameters(
        command=sys.executable,
        args=["-m", "personal_ai_mcp.obsidian.server"],
        cwd=str(PROJECT_ROOT),
    )

    async with stdio_client(server) as streams:
        read_stream, write_stream = streams

        async with ClientSession(read_stream, write_stream) as session:
            initialization = await session.initialize()

            assert (
                initialization.serverInfo.name
                == "personal-ai-obsidian-retrieval"
            )

            tools = await session.list_tools()

            assert [tool.name for tool in tools.tools] == [
                "obsidian_search"
            ]


@pytest.mark.asyncio
@pytest.mark.integration
async def test_obsidian_search_over_mcp() -> None:
    server = StdioServerParameters(
        command=sys.executable,
        args=["-m", "personal_ai_mcp.obsidian.server"],
        cwd=str(PROJECT_ROOT),
    )

    async with stdio_client(server) as streams:
        read_stream, write_stream = streams

        async with ClientSession(read_stream, write_stream) as session:
            await session.initialize()

            result = await session.call_tool(
                "obsidian_search",
                arguments={
                    "query": "Qdrant backup snapshot retention",
                    "vault_id": "personal-knowledge",
                    "limit": 3,
                    "score_threshold": 0.30,
                },
            )

            assert result.isError is False
            assert result.structuredContent is not None

            envelope = result.structuredContent

            assert envelope["schema_version"] == 1
            assert envelope["status"] == "success"
            assert envelope["error"] is None

            data = envelope["data"]

            assert data["collection"] == "obsidian_chunks_v1"
            assert data["vault_id"] == "personal-knowledge"
            assert 1 <= data["result_count"] <= 3