"""End-to-end stdio protocol test for the M06 proof server."""

from __future__ import annotations

import sys
from pathlib import Path

import pytest
from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client


PROJECT_ROOT = Path(__file__).resolve().parents[1]


@pytest.mark.asyncio
async def test_protocol_initialization_and_server_info() -> None:
    server = StdioServerParameters(
        command=sys.executable,
        args=["-m", "personal_ai_mcp.proof_server"],
        cwd=str(PROJECT_ROOT),
    )

    async with stdio_client(server) as streams:
        read_stream, write_stream = streams

        async with ClientSession(read_stream, write_stream) as session:
            initialization = await session.initialize()

            assert initialization.serverInfo.name == "personal-ai-mcp-proof"

            tools = await session.list_tools()
            tool_names = [tool.name for tool in tools.tools]

            assert tool_names == ["server_info"]

            result = await session.call_tool("server_info", arguments={})

            assert result.isError is False
            assert result.structuredContent is not None

            data = result.structuredContent

            assert data["schema_version"] == 1
            assert data["server"] == "personal-ai-mcp-proof"
            assert data["version"] == "0.1.0"
            assert data["transport"] == "stdio"
            assert data["access"] == "read-only"