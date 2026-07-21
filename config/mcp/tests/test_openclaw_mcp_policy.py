"""Validate production OpenClaw MCP registrations and allowlists."""

from __future__ import annotations

import json
from pathlib import Path

import pytest


OPENCLAW_CONFIG = (
    Path.home() / ".openclaw/openclaw.json"
)

EXPECTED_SERVERS = {
    "obsidian-retrieval": {
        "command": (
            "/Users/openclaw/server/services/mcp/"
            ".venv/bin/python"
        ),
        "args": [
            "-m",
            "personal_ai_mcp.obsidian.server",
        ],
        "cwd": "/Users/openclaw/server/services/mcp",
        "tools": {
            "obsidian_search",
            "obsidian_get_chunk",
            "obsidian_list_vaults",
            "obsidian_retrieval_status",
        },
    },
    "platform-status": {
        "command": (
            "/Users/openclaw/server/services/mcp/"
            ".venv/bin/python"
        ),
        "args": [
            "-m",
            "personal_ai_mcp.platform.server",
        ],
        "cwd": "/Users/openclaw/server/services/mcp",
        "tools": {
            "platform_status",
            "platform_health",
            "platform_versions",
            "platform_component_status",
        },
    },
}


@pytest.mark.integration
def test_openclaw_mcp_registration_policy() -> None:
    data = json.loads(
        OPENCLAW_CONFIG.read_text(encoding="utf-8")
    )

    servers = data.get("mcp", {}).get("servers", {})

    for name, expected in EXPECTED_SERVERS.items():
        assert name in servers

        server = servers[name]

        assert server.get("command") == expected["command"]
        assert server.get("args") == expected["args"]
        assert server.get("cwd") == expected["cwd"]
        assert server.get("connectTimeout") == 10
        assert server.get("timeout") == 15

        include = (
            server.get("toolFilter", {})
            .get("include", [])
        )

        assert set(include) == expected["tools"]


@pytest.mark.integration
def test_no_unapproved_mcp_server_tools() -> None:
    data = json.loads(
        OPENCLAW_CONFIG.read_text(encoding="utf-8")
    )

    servers = data.get("mcp", {}).get("servers", {})

    for name in EXPECTED_SERVERS:
        include = (
            servers[name]
            .get("toolFilter", {})
            .get("include", [])
        )

        assert include
        assert "*" not in include
        assert all("*" not in tool for tool in include)