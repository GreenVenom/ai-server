#!/bin/bash

############################################################
#
# Personal AI Platform
#
# Script: health.sh
#
# Purpose:
# Complete platform health assessment.
#
# Version: 2.2.0
#
############################################################

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/lib"

source "${LIB_DIR}/version.sh"
source "${LIB_DIR}/colors.sh"
source "${LIB_DIR}/platform.sh"

QDRANT_URL="${QDRANT_URL:-http://127.0.0.1:6333}"

OBSIDIAN_COLLECTION="obsidian_chunks_v1"
OBSIDIAN_VAULT_ID="personal-knowledge"
OBSIDIAN_EXPECTED_DOCUMENTS=7
OBSIDIAN_EXPECTED_CHUNKS=176
OBSIDIAN_MANIFEST="$HOME/server/data/obsidian/manifests/personal-knowledge.json"
OBSIDIAN_MIRROR="$HOME/server/data/obsidian/vaults/personal-knowledge"
OBSIDIAN_STATE="$HOME/server/data/obsidian/state/personal-knowledge-job-state.json"
OBSIDIAN_COMMIT="$HOME/server/data/obsidian/state/personal-knowledge-source.commit"
OBSIDIAN_LAUNCHAGENT="ai.openclaw.obsidian-sync-index"
OBSIDIAN_PLUGIN="obsidian-retrieval"
OBSIDIAN_TOOL="obsidian_search"
QDRANT_CONTAINER="${QDRANT_CONTAINER:-personal-ai-qdrant}"
QDRANT_COLLECTION="${QDRANT_COLLECTION:-m04_validation}"
QDRANT_COMPOSE_FILE="${QDRANT_COMPOSE_FILE:-$HOME/server/docker/qdrant/compose.yaml}"
QDRANT_VOLUME="${QDRANT_VOLUME:-personal-ai-qdrant-storage}"
QDRANT_SNAPSHOT_DIR="${QDRANT_SNAPSHOT_DIR:-$HOME/server/backups/qdrant/snapshots}"
QDRANT_MANIFEST_DIR="${QDRANT_MANIFEST_DIR:-$HOME/server/backups/qdrant/manifests}"
OPENCLAW_GATEWAY_PORT="${OPENCLAW_GATEWAY_PORT:-18789}"
OPENCLAW_WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/server/workspaces/main}"
OPENCLAW_SANDBOX_IMAGE="${OPENCLAW_SANDBOX_IMAGE:-openclaw-sandbox:bookworm-slim}"
EXPECTED_QDRANT_VERSION="${EXPECTED_QDRANT_VERSION:-1.18.2}"
EXPECTED_QDRANT_POINTS="${EXPECTED_QDRANT_POINTS:-5}"
EXPECTED_VECTOR_SIZE="${EXPECTED_VECTOR_SIZE:-768}"
EXPECTED_VECTOR_NAME="${EXPECTED_VECTOR_NAME:-text-dense}"
EXPECTED_DISTANCE="${EXPECTED_DISTANCE:-Cosine}"

PASS_COUNT=0
WARN_COUNT=0
FAIL_COUNT=0
START_TIME="$(date +%s)"

pass() {
    PASS_COUNT=$((PASS_COUNT + 1))
    print_success "$1"
    [[ -n "${2:-}" ]] && printf '    %s\n' "$2"
}

warn() {
    WARN_COUNT=$((WARN_COUNT + 1))
    print_warning "$1"
    [[ -n "${2:-}" ]] && printf '    %s\n' "$2"
}

fail() {
    FAIL_COUNT=$((FAIL_COUNT + 1))
    print_error "$1"
    [[ -n "${2:-}" ]] && printf '    %s\n' "$2"
}

command_check() {
    if command -v "$1" >/dev/null 2>&1; then
        pass "$1" "Installed: $(command -v "$1")"
    else
        fail "$1" "Command not found"
    fi
}

process_check() {
    if pgrep -f "$2" >/dev/null 2>&1; then
        pass "$1" "Running"
    else
        fail "$1" "Not running"
    fi
}

port_open() {
    python3 - "$1" "$2" <<'PY' >/dev/null 2>&1
import socket
import sys

sock = socket.socket()
sock.settimeout(1)
try:
    sock.connect((sys.argv[1], int(sys.argv[2])))
except OSError:
    raise SystemExit(1)
finally:
    sock.close()
PY
}

directory_check() {
    label="$1"
    path="$2"

    if [[ -d "$path" ]]; then
        pass "$label" "Directory exists: $path"
    else
        fail "$label" "Directory missing: $path"
    fi
}

writable_directory_check() {
    label="$1"
    path="$2"

    if [[ -d "$path" && -w "$path" ]]; then
        pass "$label" "Configured and writable: $path"
    else
        fail "$label" "Missing or not writable: $path"
    fi
}

qdrant_metadata() {
    curl --fail --silent --show-error \
        "${QDRANT_URL}/collections/${QDRANT_COLLECTION}" 2>/dev/null
}

print_header "Platform Health"

print_section "Commands"
command_check git
command_check docker
command_check ollama
command_check openclaw
command_check curl
command_check python3

print_section "Services"
process_check "Ollama" '[O]llama'

if docker info >/dev/null 2>&1; then
    pass "Docker" "Running"
else
    fail "Docker" "Unavailable"
fi

process_check "Tailscale" '[T]ailscale'

if command -v openclaw >/dev/null 2>&1; then
    oc_status="$(openclaw status --all 2>&1 || true)"
    if printf '%s\n' "$oc_status" | grep -Eq \
        'Gateway service.*loaded.*running|LaunchAgent.*loaded.*running'; then
        pass "OpenClaw Gateway" "LaunchAgent loaded and runtime active"
    else
        fail "OpenClaw Gateway" "Gateway service is not active"
    fi

    if printf '%s\n' "$oc_status" | grep -Eq 'Gateway.*reachable'; then
        pass "OpenClaw RPC" "Gateway connectivity probe passed"
    else
        fail "OpenClaw RPC" "Gateway connectivity probe failed"
    fi
fi

if docker inspect "$QDRANT_CONTAINER" >/dev/null 2>&1; then
    q_status="$(docker inspect "$QDRANT_CONTAINER" --format '{{.State.Status}}')"
    q_health="$(docker inspect "$QDRANT_CONTAINER" --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}')"

    if [[ "$q_status" == "running" && "$q_health" == "healthy" ]]; then
        pass "Qdrant" "Container running and healthy"
    else
        fail "Qdrant" "status=${q_status}; health=${q_health}"
    fi
else
    fail "Qdrant" "Container not found: ${QDRANT_CONTAINER}"
fi

print_section "Directories"
directory_check "Server Root" "$SERVER_ROOT"
directory_check "Configuration" "$CONFIG_DIR"
directory_check "Data" "$DATA_DIR"
directory_check "Logs" "$LOG_DIR"
directory_check "Backups" "$BACKUP_DIR"
directory_check "Models" "$MODEL_DIR"
writable_directory_check "OpenClaw Workspace" "$OPENCLAW_WORKSPACE"
directory_check "Qdrant Snapshots" "$QDRANT_SNAPSHOT_DIR"
directory_check "Qdrant Manifests" "$QDRANT_MANIFEST_DIR"

print_section "Resources"
installed_memory="$(get_memory_gb)"
if [[ "$installed_memory" -ge 24 ]]; then
    pass "Memory" "${installed_memory} GB installed"
else
    fail "Memory" "Only ${installed_memory} GB installed"
fi

free_gb="$(df -g "$SERVER_ROOT" | awk 'NR==2 {print $4}')"
if [[ -n "$free_gb" && "$free_gb" -ge 20 ]]; then
    pass "Disk Space" "${free_gb} GB available"
else
    fail "Disk Space" "Less than 20 GB available"
fi

print_section "APIs"
if curl --fail --silent --show-error \
    "http://${OLLAMA_HOST}/api/version" >/dev/null 2>&1; then
    pass "Ollama API" "Reachable: http://${OLLAMA_HOST}/api/version"
else
    fail "Ollama API" "Unreachable"
fi

if port_open 127.0.0.1 "$OPENCLAW_GATEWAY_PORT"; then
    pass "OpenClaw Gateway Port" \
        "Port 127.0.0.1:${OPENCLAW_GATEWAY_PORT} open"
else
    fail "OpenClaw Gateway Port" "Port closed"
fi

if curl --fail --silent --show-error \
    "${QDRANT_URL}/readyz" >/dev/null 2>&1; then
    pass "Qdrant REST Readiness" "Reachable: ${QDRANT_URL}/readyz"
else
    fail "Qdrant REST Readiness" "Readiness probe failed"
fi

if port_open 127.0.0.1 6334; then
    pass "Qdrant gRPC Port" "Port 127.0.0.1:6334 open"
else
    fail "Qdrant gRPC Port" "Port 127.0.0.1:6334 closed"
fi

print_section "Models"
for model in nomic-embed-text gemma4:12b qwen3:14b; do
    if ollama list 2>/dev/null | awk 'NR > 1 {print $1}' |
        grep -Eq "^${model}(:latest)?$"; then
        pass "$model" "Installed"
    else
        fail "$model" "Not installed"
    fi
done

if [[ -f "$HOME/.openclaw/openclaw.json" ]]; then
    if python3 - "$HOME/.openclaw/openclaw.json" <<'PY' >/dev/null 2>&1
import json
import sys

with open(sys.argv[1], encoding="utf-8") as handle:
    data = json.load(handle)

model = data["agents"]["defaults"]["model"]
assert model["primary"] == "ollama/gemma4:12b"
assert "ollama/qwen3:14b" in model.get("fallbacks", [])
PY
    then
        pass "OpenClaw Models" \
            "Primary ollama/gemma4:12b; fallback ollama/qwen3:14b"
    else
        fail "OpenClaw Models" "Unexpected model configuration"
    fi
else
    fail "OpenClaw Models" "Configuration file not found"
fi

print_section "OpenClaw Health"
if openclaw status --all >/dev/null 2>&1; then
    pass "OpenClaw Configuration" "Configuration is valid"
else
    fail "OpenClaw Configuration" "Status/configuration check failed"
fi

if openclaw status --all 2>&1 | grep -Eq \
    'ws://127\.0\.0\.1:18789.*loopback|Bind: loopback'; then
    pass "OpenClaw Binding" \
        "Gateway is loopback-only on 127.0.0.1:18789"
else
    fail "OpenClaw Binding" "Loopback binding not confirmed"
fi

if [[ -S "$HOME/.docker/run/docker.sock" ]]; then
    pass "OpenClaw Docker Socket" \
        "Configured and available: $HOME/.docker/run/docker.sock"
else
    fail "OpenClaw Docker Socket" "Docker socket unavailable"
fi

if docker image inspect "$OPENCLAW_SANDBOX_IMAGE" >/dev/null 2>&1; then
    pass "OpenClaw Sandbox Image" "Available: $OPENCLAW_SANDBOX_IMAGE"
else
    fail "OpenClaw Sandbox Image" "Image unavailable"
fi

if [[ -f "$HOME/.openclaw/openclaw.json" ]] &&
   python3 - "$HOME/.openclaw/openclaw.json" <<'PY' >/dev/null 2>&1
import json
import sys

with open(sys.argv[1], encoding="utf-8") as handle:
    data = json.load(handle)

defaults = data.get("agents", {}).get("defaults", {})
sandbox = defaults.get("sandbox", {})
assert sandbox.get("mode") == "all"
PY
then
    pass "OpenClaw Sandbox Policy" \
        "Sandbox=all; production policy configured"
else
    fail "OpenClaw Sandbox Policy" "Expected sandbox policy not found"
fi

security_output="$(openclaw security audit --deep 2>&1 || true)"
if printf '%s\n' "$security_output" | grep -Eq \
    'Summary:[[:space:]]*0 critical|0 critical findings'; then
    pass "OpenClaw Security" "Deep audit reports 0 critical findings"
else
    fail "OpenClaw Security" "Critical finding count could not be confirmed"
fi

print_section "Qdrant Health"
if [[ -f "$QDRANT_COMPOSE_FILE" ]]; then
    pass "Qdrant Compose" "Present: $QDRANT_COMPOSE_FILE"
else
    fail "Qdrant Compose" "Missing: $QDRANT_COMPOSE_FILE"
fi

q_image="$(docker inspect "$QDRANT_CONTAINER" --format '{{.Config.Image}}' 2>/dev/null || true)"
if [[ "$q_image" == "qdrant/qdrant:v${EXPECTED_QDRANT_VERSION}" ]]; then
    pass "Qdrant Image" "Pinned: $q_image"
else
    fail "Qdrant Image" "Unexpected image: ${q_image:-missing}"
fi

q_version="$(curl --fail --silent --show-error "$QDRANT_URL" 2>/dev/null |
    python3 -c 'import json,sys; print(json.load(sys.stdin).get("version", ""))' 2>/dev/null || true)"
if [[ "$q_version" == "$EXPECTED_QDRANT_VERSION" ]]; then
    pass "Qdrant Version" "Qdrant $q_version"
else
    fail "Qdrant Version" "Expected ${EXPECTED_QDRANT_VERSION}; got ${q_version:-unknown}"
fi

q_restart="$(docker inspect "$QDRANT_CONTAINER" --format '{{.HostConfig.RestartPolicy.Name}}' 2>/dev/null || true)"
if [[ "$q_restart" == "always" ]]; then
    pass "Qdrant Restart Policy" "restart=always"
else
    fail "Qdrant Restart Policy" "Expected always; got ${q_restart:-unknown}"
fi

if docker volume inspect "$QDRANT_VOLUME" >/dev/null 2>&1; then
    pass "Qdrant Data Volume" "Available: $QDRANT_VOLUME"
else
    fail "Qdrant Data Volume" "Missing: $QDRANT_VOLUME"
fi

metadata="$(qdrant_metadata || true)"
if [[ -n "$metadata" ]]; then
    values="$(python3 - "$metadata" "$EXPECTED_VECTOR_NAME" <<'PY' 2>/dev/null || true
import json
import sys

data = json.loads(sys.argv[1])["result"]
vector = data["config"]["params"]["vectors"][sys.argv[2]]
print(data["status"])
print(data["points_count"])
print(vector["size"])
print(vector["distance"])
PY
)"
    q_collection_status="$(printf '%s\n' "$values" | sed -n '1p')"
    q_points="$(printf '%s\n' "$values" | sed -n '2p')"
    q_size="$(printf '%s\n' "$values" | sed -n '3p')"
    q_distance="$(printf '%s\n' "$values" | sed -n '4p')"

    if [[ "$q_collection_status" == "green" ]]; then
        pass "Qdrant Collection" "${QDRANT_COLLECTION} is green"
    else
        fail "Qdrant Collection" "status=${q_collection_status:-unknown}"
    fi

    if [[ "$q_points" == "$EXPECTED_QDRANT_POINTS" ]]; then
        pass "Qdrant Point Count" "$q_points points"
    else
        fail "Qdrant Point Count" "Expected $EXPECTED_QDRANT_POINTS; got ${q_points:-unknown}"
    fi

    if [[ "$q_size" == "$EXPECTED_VECTOR_SIZE" &&
          "$q_distance" == "$EXPECTED_DISTANCE" ]]; then
        pass "Qdrant Vector Contract" \
            "${EXPECTED_VECTOR_NAME}: ${q_size} dimensions, ${q_distance}"
    else
        fail "Qdrant Vector Contract" \
            "name=${EXPECTED_VECTOR_NAME}; size=${q_size:-unknown}; distance=${q_distance:-unknown}"
    fi
else
    fail "Qdrant Collection" "Unable to inspect ${QDRANT_COLLECTION}"
    fail "Qdrant Point Count" "Collection unavailable"
    fail "Qdrant Vector Contract" "Collection unavailable"
fi


print_section "Obsidian Health"

if [[ -d "$OBSIDIAN_MIRROR" ]]; then
    pass "Obsidian Mirror" "Available: $OBSIDIAN_MIRROR"
else
    fail "Obsidian Mirror" "Missing: $OBSIDIAN_MIRROR"
fi

if [[ -f "$OBSIDIAN_MANIFEST" ]]; then
    pass "Obsidian Manifest" "Present: $OBSIDIAN_MANIFEST"
else
    fail "Obsidian Manifest" "Missing: $OBSIDIAN_MANIFEST"
fi

if [[ -f "$OBSIDIAN_COMMIT" ]]; then
    obsidian_commit="$(cat "$OBSIDIAN_COMMIT" 2>/dev/null || true)"
    [[ -n "$obsidian_commit" ]] && \
        pass "Obsidian Source Commit" "$obsidian_commit" || \
        fail "Obsidian Source Commit" "Commit state is empty"
else
    fail "Obsidian Source Commit" "Missing: $OBSIDIAN_COMMIT"
fi

if launchctl print \
    "gui/$(id -u)/${OBSIDIAN_LAUNCHAGENT}" \
    >/dev/null 2>&1
then
    pass "Obsidian LaunchAgent" "Loaded: $OBSIDIAN_LAUNCHAGENT"
else
    fail "Obsidian LaunchAgent" "Not loaded: $OBSIDIAN_LAUNCHAGENT"
fi

if [[ -f "$OBSIDIAN_STATE" ]]; then
    obsidian_job_status="$(
        python3 - "$OBSIDIAN_STATE" <<'PYJOB' 2>/dev/null || true
import json
import sys

with open(sys.argv[1], encoding="utf-8") as handle:
    data = json.load(handle)

print(data.get("status", "unknown"))
PYJOB
    )"

    if [[ "$obsidian_job_status" == "success" ]]; then
        pass "Obsidian Scheduled Job" "Last run completed successfully"
    else
        fail "Obsidian Scheduled Job" \
            "Last status=${obsidian_job_status:-unknown}"
    fi
else
    fail "Obsidian Scheduled Job" "State file missing: $OBSIDIAN_STATE"
fi

obsidian_metadata="$(
    curl --fail --silent --show-error \
        "${QDRANT_URL}/collections/${OBSIDIAN_COLLECTION}" \
        2>/dev/null || true
)"

if [[ -n "$obsidian_metadata" ]]; then
    obsidian_values="$(
        python3 - "$obsidian_metadata" "$EXPECTED_VECTOR_NAME" <<'PYMETA' \
            2>/dev/null || true
import json
import sys

data = json.loads(sys.argv[1])["result"]
vector = data["config"]["params"]["vectors"][sys.argv[2]]

print(data["status"])
print(data["points_count"])
print(vector["size"])
print(vector["distance"])
PYMETA
    )"

    obsidian_collection_status="$(printf '%s\n' "$obsidian_values" | sed -n '1p')"
    obsidian_total_points="$(printf '%s\n' "$obsidian_values" | sed -n '2p')"
    obsidian_vector_size="$(printf '%s\n' "$obsidian_values" | sed -n '3p')"
    obsidian_distance="$(printf '%s\n' "$obsidian_values" | sed -n '4p')"

    if [[ "$obsidian_collection_status" == "green" ]]; then
        pass "Obsidian Collection" \
            "${OBSIDIAN_COLLECTION} is green; total=${obsidian_total_points}"
    else
        fail "Obsidian Collection" \
            "status=${obsidian_collection_status:-unknown}"
    fi

    if [[ "$obsidian_vector_size" == "$EXPECTED_VECTOR_SIZE" &&
          "$obsidian_distance" == "$EXPECTED_DISTANCE" ]]; then
        pass "Obsidian Vector Contract" \
            "${EXPECTED_VECTOR_NAME}: ${obsidian_vector_size} dimensions, ${obsidian_distance}"
    else
        fail "Obsidian Vector Contract" \
            "size=${obsidian_vector_size:-unknown}; distance=${obsidian_distance:-unknown}"
    fi
else
    fail "Obsidian Collection" \
        "Unable to inspect ${OBSIDIAN_COLLECTION}"
    fail "Obsidian Vector Contract" "Collection unavailable"
fi

obsidian_counts="$(
    PYTHONPATH="$HOME/server/services/obsidian/src" \
    "$HOME/server/services/obsidian/venv/bin/python" - \
        "$OBSIDIAN_MANIFEST" \
        "$OBSIDIAN_MIRROR" \
        "$QDRANT_URL" \
        "$OBSIDIAN_COLLECTION" \
        "$OBSIDIAN_VAULT_ID" \
        2>/dev/null <<'PYCOUNT' || true
import json
import sys
import urllib.request
from pathlib import Path

from obsidian_ingest.manifest import load_manifest

manifest_path = Path(sys.argv[1])
mirror_root = Path(sys.argv[2])
qdrant_url = sys.argv[3]
collection = sys.argv[4]
vault_id = sys.argv[5]

manifest = load_manifest(manifest_path, required=True)

document_count = len(manifest.documents)
chunk_ids = {
    chunk_id
    for document in manifest.documents.values()
    for chunk_id in document.chunk_ids
}
mirror_count = len(list(mirror_root.rglob("*.md")))

request = urllib.request.Request(
    f"{qdrant_url}/collections/{collection}/points/scroll",
    data=json.dumps({
        "limit": 10000,
        "with_payload": False,
        "with_vector": False,
        "filter": {
            "must": [{
                "key": "vault_id",
                "match": {"value": vault_id},
            }]
        },
    }).encode("utf-8"),
    method="POST",
    headers={"Content-Type": "application/json"},
)

with urllib.request.urlopen(request, timeout=30) as response:
    points = json.load(response)["result"]["points"]

qdrant_ids = {point["id"] for point in points}

print(document_count)
print(len(chunk_ids))
print(mirror_count)
print(len(qdrant_ids))
print("true" if chunk_ids == qdrant_ids else "false")
PYCOUNT
)"

obsidian_documents="$(printf '%s\n' "$obsidian_counts" | sed -n '1p')"
obsidian_chunks="$(printf '%s\n' "$obsidian_counts" | sed -n '2p')"
obsidian_mirror_documents="$(printf '%s\n' "$obsidian_counts" | sed -n '3p')"
obsidian_qdrant_chunks="$(printf '%s\n' "$obsidian_counts" | sed -n '4p')"
obsidian_reconciled="$(printf '%s\n' "$obsidian_counts" | sed -n '5p')"

if [[ "$obsidian_documents" == "$OBSIDIAN_EXPECTED_DOCUMENTS" &&
      "$obsidian_mirror_documents" == "$OBSIDIAN_EXPECTED_DOCUMENTS" ]]; then
    pass "Obsidian Document Count" \
        "${obsidian_documents} indexed documents"
else
    fail "Obsidian Document Count" \
        "manifest=${obsidian_documents:-unknown}; mirror=${obsidian_mirror_documents:-unknown}"
fi

if [[ "$obsidian_chunks" == "$OBSIDIAN_EXPECTED_CHUNKS" &&
      "$obsidian_qdrant_chunks" == "$OBSIDIAN_EXPECTED_CHUNKS" &&
      "$obsidian_reconciled" == "true" ]]; then
    pass "Obsidian Chunk Reconciliation" \
        "${obsidian_chunks} production chunks"
else
    fail "Obsidian Chunk Reconciliation" \
        "manifest=${obsidian_chunks:-unknown}; qdrant=${obsidian_qdrant_chunks:-unknown}; reconciled=${obsidian_reconciled:-unknown}"
fi

if openclaw plugins inspect "$OBSIDIAN_PLUGIN" \
    --runtime --json 2>/dev/null |
    python3 -c '
import json
import sys

data = json.load(sys.stdin)
plugin = data.get("plugin", {})
tools = plugin.get("toolNames", [])

raise SystemExit(
    0 if (
        plugin.get("status") == "loaded"
        and "obsidian_search" in tools
    ) else 1
)
'
then
    pass "Obsidian OpenClaw Tool" \
        "${OBSIDIAN_TOOL} loaded through ${OBSIDIAN_PLUGIN}"
else
    fail "Obsidian OpenClaw Tool" \
        "Plugin or tool unavailable"
fi

print_section "Summary"
DURATION=$(( $(date +%s) - START_TIME ))
TOTAL=$((PASS_COUNT + WARN_COUNT + FAIL_COUNT))
printf 'Checks   : %s\n' "$TOTAL"
printf 'Passed   : %s\n' "$PASS_COUNT"
printf 'Warnings : %s\n' "$WARN_COUNT"
printf 'Failed   : %s\n' "$FAIL_COUNT"
printf 'Duration : %ss\n' "$DURATION"

if [[ "$FAIL_COUNT" -gt 0 ]]; then
    printf 'Overall  : FAIL\n'
    exit 1
elif [[ "$WARN_COUNT" -gt 0 ]]; then
    printf 'Overall  : WARN\n'
    exit 0
else
    printf 'Overall  : PASS\n'
    exit 0
fi