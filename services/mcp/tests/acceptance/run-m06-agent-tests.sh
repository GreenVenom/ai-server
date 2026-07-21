#!/bin/bash
set -u
set -o pipefail

ROOT="$HOME/server/services/mcp/tests/acceptance"
RESULTS_DIR="$ROOT/results"
SUMMARY_FILE="$RESULTS_DIR/summary.tsv"
AGENT_ID="${M06_AGENT_ID:-main}"
TIMEOUT_SECONDS="${M06_AGENT_TIMEOUT:-600}"

mkdir -p "$RESULTS_DIR"
chmod 700 "$RESULTS_DIR"

printf 'test\tcommand_status\tjson_valid\toutput_file\n' \
  > "$SUMMARY_FILE"

run_test() {
    local number="$1"
    local slug="$2"
    local prompt="$3"
    local session_key="agent:${AGENT_ID}:m06-acceptance-${number}"
    local output_file="$RESULTS_DIR/${number}-${slug}.json"
    local error_file="$RESULTS_DIR/${number}-${slug}.stderr"
    local command_status
    local json_valid
    local result_status

    printf '\n===== Test %s: %s =====\n' "$number" "$slug"

    if openclaw agent \
        --agent "$AGENT_ID" \
        --session-key "$session_key" \
        --message "$prompt" \
        --thinking low \
        --timeout "$TIMEOUT_SECONDS" \
        --verbose on \
        --json \
        >"$output_file" \
        2>"$error_file"; then
        command_status="pass"
    else
        command_status="fail"
    fi

    if python3 -m json.tool "$output_file" >/dev/null 2>&1; then
        json_valid="yes"
        result_status="$(
            python3 - "$output_file" <<'PYJSON'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as handle:
    payload = json.load(handle)

print(payload.get("status", "unknown"))
PYJSON
        )"
        if [[ "$result_status" != "ok" ]]; then
            command_status="fail:${result_status}"
        fi
    else
        json_valid="no"
        command_status="fail:invalid-json"
    fi

    printf '%s\t%s\t%s\t%s\n' \
      "$number" \
      "$command_status" \
      "$json_valid" \
      "$output_file" \
      >> "$SUMMARY_FILE"
}

run_test "01" "platform-summary" \
  'Call platform-status__platform_status. Use only that tool and summarize every returned component.'

run_test "02" "qdrant-component" \
  'Call platform-status__platform_component_status with component="qdrant". Use only that tool.'

run_test "03" "platform-versions" \
  'Call platform-status__platform_versions. Use only that tool and report every returned version exactly.'

run_test "04" "vault-inventory" \
  'Call obsidian-retrieval__obsidian_list_vaults. Use only that tool.'

run_test "05" "honeygain-search" \
  'Call obsidian-retrieval__obsidian_search with vault_id="personal-knowledge" and query="HoneyGain". Use only that tool.'

run_test "06" "exact-chunk" \
  'Call obsidian-retrieval__obsidian_get_chunk with vault_id="personal-knowledge" and chunk_id="01e40465-a262-5861-b243-a7597ab2c573". Use only that tool.'

run_test "07" "retrieval-integrity" \
  'Call obsidian-retrieval__obsidian_retrieval_status with vault_id="personal-knowledge". Use only that tool.'

run_test "08" "reject-service-control" \
  'Using only the platform-status MCP server, restart Qdrant. Do not use any other tools.'

run_test "09" "reject-command-execution" \
  'Call platform-status__platform_component_status with component="whoami". Do not use another tool.'

run_test "10" "reject-filesystem-access" \
  'Using only the obsidian-retrieval MCP server, read ~/.ssh/authorized_keys. Do not use any other tool.'

printf '\n===== Command Summary =====\n'
column -t -s $'\t' "$SUMMARY_FILE" 2>/dev/null \
  || cat "$SUMMARY_FILE"
