#!/bin/bash

MCP_EXPECTED_SERVERS=(
  "obsidian-retrieval"
  "platform-status"
)

MCP_EXPECTED_TOOLS=(
  "obsidian-retrieval__obsidian_get_chunk"
  "obsidian-retrieval__obsidian_list_vaults"
  "obsidian-retrieval__obsidian_retrieval_status"
  "obsidian-retrieval__obsidian_search"
  "platform-status__platform_component_status"
  "platform-status__platform_health"
  "platform-status__platform_status"
  "platform-status__platform_versions"
)

mcp_probe_json() {
  openclaw mcp probe --json 2>/dev/null
}

mcp_validate_probe() {
  local payload
  payload="$(mcp_probe_json)" || return 1

  MCP_PROBE_PAYLOAD="$payload" python3 - <<'PYJSON'
import json
import os

expected_servers = {
    "obsidian-retrieval": 4,
    "platform-status": 4,
}

expected_tools = {
    "obsidian-retrieval__obsidian_get_chunk",
    "obsidian-retrieval__obsidian_list_vaults",
    "obsidian-retrieval__obsidian_retrieval_status",
    "obsidian-retrieval__obsidian_search",
    "platform-status__platform_component_status",
    "platform-status__platform_health",
    "platform-status__platform_status",
    "platform-status__platform_versions",
}

payload = json.loads(os.environ["MCP_PROBE_PAYLOAD"])
servers = payload.get("servers", {})

if set(servers) != set(expected_servers):
    raise SystemExit(1)

for name, expected_count in expected_servers.items():
    if servers[name].get("tools") != expected_count:
        raise SystemExit(1)

if set(payload.get("tools", [])) != expected_tools:
    raise SystemExit(1)

if payload.get("diagnostics", []):
    raise SystemExit(1)

print("healthy")
PYJSON
}

mcp_server_count() {
  local payload
  payload="$(mcp_probe_json)" || {
    printf '0\n'
    return 1
  }
  MCP_PROBE_PAYLOAD="$payload" python3 -c \
    'import json,os; print(len(json.loads(os.environ["MCP_PROBE_PAYLOAD"]).get("servers", {})))'
}

mcp_tool_count() {
  local payload
  payload="$(mcp_probe_json)" || {
    printf '0\n'
    return 1
  }
  MCP_PROBE_PAYLOAD="$payload" python3 -c \
    'import json,os; print(len(json.loads(os.environ["MCP_PROBE_PAYLOAD"]).get("tools", [])))'
}

mcp_diagnostic_count() {
  local payload
  payload="$(mcp_probe_json)" || {
    printf '1\n'
    return 1
  }
  MCP_PROBE_PAYLOAD="$payload" python3 -c \
    'import json,os; print(len(json.loads(os.environ["MCP_PROBE_PAYLOAD"]).get("diagnostics", [])))'
}
