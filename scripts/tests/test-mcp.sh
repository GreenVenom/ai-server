#!/bin/bash
set -euo pipefail

source "$HOME/server/scripts/lib/mcp.sh"

[[ "$(mcp_server_count)" == "2" ]]
[[ "$(mcp_tool_count)" == "8" ]]
[[ "$(mcp_diagnostic_count)" == "0" ]]
[[ "$(mcp_validate_probe)" == "healthy" ]]

printf 'PASS: MCP production inventory\n'
