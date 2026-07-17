#!/bin/bash

############################################################
#
# Personal AI Platform
#
# Script: status.sh
#
# Purpose:
# Quick operational status overview.
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
QDRANT_CONTAINER="${QDRANT_CONTAINER:-personal-ai-qdrant}"
QDRANT_COLLECTION="${QDRANT_COLLECTION:-m04_validation}"
OPENCLAW_GATEWAY_PORT="${OPENCLAW_GATEWAY_PORT:-18789}"
OPENCLAW_WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/server/workspaces/main}"
OPENCLAW_SANDBOX_IMAGE="${OPENCLAW_SANDBOX_IMAGE:-openclaw-sandbox:bookworm-slim}"

STATUS_WARNINGS=0
STATUS_FAILURES=0

ok() {
    print_success "$1"
    [[ -n "${2:-}" ]] && printf '    %s\n' "$2"
}

warn() {
    STATUS_WARNINGS=$((STATUS_WARNINGS + 1))
    print_warning "$1"
    [[ -n "${2:-}" ]] && printf '    %s\n' "$2"
}

fail() {
    STATUS_FAILURES=$((STATUS_FAILURES + 1))
    print_error "$1"
    [[ -n "${2:-}" ]] && printf '    %s\n' "$2"
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

port_open() {
    python3 - "$1" "$2" <<'PY' >/dev/null 2>&1
import socket
import sys

host = sys.argv[1]
port = int(sys.argv[2])

sock = socket.socket()
sock.settimeout(1)
try:
    sock.connect((host, port))
except OSError:
    raise SystemExit(1)
finally:
    sock.close()
PY
}

process_running() {
    pgrep -f "$1" >/dev/null 2>&1
}

openclaw_status_output() {
    openclaw status --all 2>&1
}

qdrant_container_status() {
    docker inspect "$QDRANT_CONTAINER" \
        --format '{{.State.Status}}' 2>/dev/null
}

qdrant_health_status() {
    docker inspect "$QDRANT_CONTAINER" \
        --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' \
        2>/dev/null
}

qdrant_version() {
    curl --fail --silent --show-error \
        "${QDRANT_URL}" 2>/dev/null |
    python3 -c '
import json
import sys

try:
    data = json.load(sys.stdin)
except Exception:
    raise SystemExit(1)

print(data.get("version", "unknown"))
' 2>/dev/null
}

qdrant_collection_summary() {
    metadata="$(
        curl --fail --silent --show-error \
            "${QDRANT_URL}/collections/${QDRANT_COLLECTION}" 2>/dev/null
    )" || return 1

    python3 - "$metadata" "$QDRANT_COLLECTION" <<'PY' 2>/dev/null
import json
import sys

payload = json.loads(sys.argv[1])
collection = sys.argv[2]
data = payload["result"]
print(
    "{}: status={}, points={}".format(
        collection,
        data.get("status", "unknown"),
        data.get("points_count", "unknown"),
    )
)
PY
}

print_header "Platform Status"

printf 'Platform : %s\n' "$PLATFORM_VERSION"
printf 'Hostname : %s\n' "$(get_hostname)"
printf '\n'

print_section "Core Services"

if process_running '[O]llama'; then
    ok "Ollama" "Running"
else
    fail "Ollama" "Not running"
fi

if docker info >/dev/null 2>&1; then
    ok "Docker" "Running"
else
    fail "Docker" "Unavailable"
fi

if process_running '[T]ailscale'; then
    ok "Tailscale" "Running"
else
    fail "Tailscale" "Not running"
fi

if command_exists openclaw; then
    oc_status="$(openclaw_status_output || true)"
    if printf '%s\n' "$oc_status" | grep -Eq \
        'Gateway service.*loaded.*running|LaunchAgent.*loaded.*running'; then
        ok "OpenClaw Gateway" "LaunchAgent loaded and runtime active"
    else
        fail "OpenClaw Gateway" "Gateway service is not active"
    fi

    if printf '%s\n' "$oc_status" | grep -Eq \
        'Gateway.*reachable|Gateway connectivity probe passed'; then
        ok "OpenClaw RPC" "Gateway connectivity probe passed"
    else
        fail "OpenClaw RPC" "Gateway connectivity probe failed"
    fi
else
    fail "OpenClaw Gateway" "openclaw command is unavailable"
    fail "OpenClaw RPC" "Cannot probe gateway"
    oc_status=""
fi

if docker info >/dev/null 2>&1; then
    q_status="$(qdrant_container_status || true)"
    q_health="$(qdrant_health_status || true)"

    if [[ "$q_status" == "running" && "$q_health" == "healthy" ]]; then
        ok "Qdrant" "Container running and healthy"
    elif [[ "$q_status" == "running" ]]; then
        warn "Qdrant" "Container running; health=${q_health:-unknown}"
    elif [[ -n "$q_status" ]]; then
        fail "Qdrant" "Container status=${q_status}"
    else
        fail "Qdrant" "Container not found: ${QDRANT_CONTAINER}"
    fi
else
    fail "Qdrant" "Docker unavailable"
fi

print_section "Endpoints"

if curl --fail --silent --show-error \
    "http://${OLLAMA_HOST}/api/version" >/dev/null 2>&1; then
    ok "Ollama API" "Reachable: http://${OLLAMA_HOST}/api/version"
else
    fail "Ollama API" "Unreachable: http://${OLLAMA_HOST}/api/version"
fi

if port_open 127.0.0.1 "$OPENCLAW_GATEWAY_PORT"; then
    ok "OpenClaw Gateway" \
        "Port 127.0.0.1:${OPENCLAW_GATEWAY_PORT} open"
else
    fail "OpenClaw Gateway" \
        "Port 127.0.0.1:${OPENCLAW_GATEWAY_PORT} closed"
fi

if curl --fail --silent --show-error \
    "${QDRANT_URL}/readyz" >/dev/null 2>&1; then
    ok "Qdrant REST" "Ready: ${QDRANT_URL}/readyz"
else
    fail "Qdrant REST" "Unreachable: ${QDRANT_URL}/readyz"
fi

if port_open 127.0.0.1 6334; then
    ok "Qdrant gRPC" "Port 127.0.0.1:6334 open"
else
    fail "Qdrant gRPC" "Port 127.0.0.1:6334 closed"
fi

print_section "OpenClaw"

if command_exists openclaw; then
    oc_version="$(openclaw --version 2>/dev/null | head -n 1 || true)"
    [[ -n "$oc_version" ]] && \
        ok "OpenClaw Version" "$oc_version" || \
        warn "OpenClaw Version" "Unable to determine version"

    if [[ -f "$HOME/.openclaw/openclaw.json" ]]; then
        model_summary="$(python3 - "$HOME/.openclaw/openclaw.json" <<'PY' 2>/dev/null || true
import json
import sys

with open(sys.argv[1], encoding="utf-8") as handle:
    data = json.load(handle)

model = data.get("agents", {}).get("defaults", {}).get("model", {})
primary = model.get("primary", "unknown")
fallbacks = model.get("fallbacks", [])
fallback = fallbacks[0] if fallbacks else "none"
print("Primary {}; fallback {}".format(primary, fallback))
PY
)"
        [[ -n "$model_summary" ]] && \
            ok "OpenClaw Models" "$model_summary" || \
            warn "OpenClaw Models" "Unable to read model configuration"
    else
        warn "OpenClaw Models" "Configuration file not found"
    fi
fi

if docker ps --format '{{.Image}}' 2>/dev/null |
    grep -Fx "$OPENCLAW_SANDBOX_IMAGE" >/dev/null 2>&1; then
    ok "OpenClaw Sandbox Runtime" "Sandbox runtime active"
else
    warn "OpenClaw Sandbox Runtime" \
        "No sandbox runtime is currently running; it may be created on demand"
fi

print_section "Qdrant"

q_version="$(qdrant_version || true)"
[[ -n "$q_version" ]] && \
    ok "Qdrant Version" "Qdrant ${q_version}" || \
    fail "Qdrant Version" "Unable to query version"

q_collection="$(qdrant_collection_summary || true)"
[[ -n "$q_collection" ]] && \
    ok "Qdrant Validation Collection" "$q_collection" || \
    fail "Qdrant Validation Collection" \
        "Unable to inspect ${QDRANT_COLLECTION}"

printf '\n'
printf 'OpenClaw Workspace : %s\n' "$OPENCLAW_WORKSPACE"
printf 'Sandbox Image      : %s\n' "$OPENCLAW_SANDBOX_IMAGE"
printf 'Qdrant Container   : %s\n' "$QDRANT_CONTAINER"
printf 'Qdrant Collection  : %s\n' "$QDRANT_COLLECTION"
printf 'Disk Free          : %s\n' "$(get_disk_free)"
printf 'Memory             : %s GB\n' "$(get_memory_gb)"
printf '\n'

if [[ "$STATUS_FAILURES" -gt 0 ]]; then
    overall="FAIL"
elif [[ "$STATUS_WARNINGS" -gt 0 ]]; then
    overall="WARN"
else
    overall="PASS"
fi

printf 'Overall Status     : %s\n' "$overall"

[[ "$STATUS_FAILURES" -eq 0 ]]
