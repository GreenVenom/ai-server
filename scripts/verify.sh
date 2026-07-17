#!/bin/bash

############################################################
#
# Personal AI Platform
#
# Script: verify.sh
#
# Purpose:
# Production readiness verification.
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
QDRANT_COMPOSE_FILE="${QDRANT_COMPOSE_FILE:-$HOME/server/docker/qdrant/compose.yaml}"
QDRANT_VOLUME="${QDRANT_VOLUME:-personal-ai-qdrant-storage}"
QDRANT_SNAPSHOT_DIR="${QDRANT_SNAPSHOT_DIR:-$HOME/server/backups/qdrant/snapshots}"
QDRANT_MANIFEST_DIR="${QDRANT_MANIFEST_DIR:-$HOME/server/backups/qdrant/manifests}"
QDRANT_PERSISTENCE_TEST="${QDRANT_PERSISTENCE_TEST:-$HOME/server/scripts/tests/qdrant-persistence-check.sh}"
OPENCLAW_GATEWAY_PORT="${OPENCLAW_GATEWAY_PORT:-18789}"
OPENCLAW_WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/server/workspaces/main}"
OPENCLAW_SANDBOX_IMAGE="${OPENCLAW_SANDBOX_IMAGE:-openclaw-sandbox:bookworm-slim}"
EXPECTED_QDRANT_VERSION="${EXPECTED_QDRANT_VERSION:-1.18.2}"
EXPECTED_QDRANT_IMAGE="${EXPECTED_QDRANT_IMAGE:-qdrant/qdrant:v1.18.2}"
EXPECTED_QDRANT_POINTS="${EXPECTED_QDRANT_POINTS:-5}"
EXPECTED_VECTOR_NAME="${EXPECTED_VECTOR_NAME:-text-dense}"
EXPECTED_VECTOR_SIZE="${EXPECTED_VECTOR_SIZE:-768}"
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

print_header "Production Verification"

print_section "Required Commands"
for command_name in git ollama docker openclaw curl python3; do
    command_check "$command_name"
done

print_section "Required Services"
if pgrep -f '[O]llama' >/dev/null 2>&1; then
    pass "Ollama" "Running"
else
    fail "Ollama" "Not running"
fi

if docker info >/dev/null 2>&1; then
    pass "Docker" "Running"
else
    fail "Docker" "Unavailable"
fi

if pgrep -f '[T]ailscale' >/dev/null 2>&1; then
    pass "Tailscale" "Running"
else
    fail "Tailscale" "Not running"
fi

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

if printf '%s\n' "$oc_status" | grep -Eq \
    'ws://127\.0\.0\.1:18789.*loopback|Bind: loopback'; then
    pass "OpenClaw Binding" \
        "Gateway is loopback-only on 127.0.0.1:18789"
else
    fail "OpenClaw Binding" "Loopback binding not confirmed"
fi

q_status="$(docker inspect "$QDRANT_CONTAINER" --format '{{.State.Status}}' 2>/dev/null || true)"
q_health="$(docker inspect "$QDRANT_CONTAINER" --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' 2>/dev/null || true)"
if [[ "$q_status" == "running" && "$q_health" == "healthy" ]]; then
    pass "Qdrant" "Container running and healthy"
else
    fail "Qdrant" "status=${q_status:-missing}; health=${q_health:-unknown}"
fi

print_section "Required APIs"
if curl --fail --silent --show-error \
    "http://${OLLAMA_HOST}/api/version" >/dev/null 2>&1; then
    pass "Ollama API" "Reachable: http://${OLLAMA_HOST}/api/version"
else
    fail "Ollama API" "Unreachable"
fi

if port_open 127.0.0.1 "$OPENCLAW_GATEWAY_PORT"; then
    pass "OpenClaw Gateway" \
        "Port 127.0.0.1:${OPENCLAW_GATEWAY_PORT} open"
else
    fail "OpenClaw Gateway" "Gateway port closed"
fi

if curl --fail --silent --show-error \
    "${QDRANT_URL}/readyz" >/dev/null 2>&1; then
    pass "Qdrant REST" "Ready: ${QDRANT_URL}/readyz"
else
    fail "Qdrant REST" "Readiness probe failed"
fi

if port_open 127.0.0.1 6334; then
    pass "Qdrant gRPC" "Port 127.0.0.1:6334 open"
else
    fail "Qdrant gRPC" "Port 127.0.0.1:6334 closed"
fi

print_section "Required Directories"
for spec in \
    "Server Root|$SERVER_ROOT" \
    "Models|$MODEL_DIR" \
    "OpenClaw Workspace|$OPENCLAW_WORKSPACE" \
    "Qdrant Snapshots|$QDRANT_SNAPSHOT_DIR" \
    "Qdrant Manifests|$QDRANT_MANIFEST_DIR"; do
    label="${spec%%|*}"
    path="${spec#*|}"
    if [[ -d "$path" ]]; then
        pass "$label" "Directory exists: $path"
    else
        fail "$label" "Directory missing: $path"
    fi
done

print_section "Required Models"
for model in nomic-embed-text gemma4:12b qwen3:14b; do
    if ollama list 2>/dev/null | awk 'NR > 1 {print $1}' |
        grep -Eq "^${model}(:latest)?$"; then
        pass "$model" "Installed"
    else
        fail "$model" "Not installed"
    fi
done

if [[ -f "$HOME/.openclaw/openclaw.json" ]] &&
   python3 - "$HOME/.openclaw/openclaw.json" <<'PY' >/dev/null 2>&1
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

print_section "OpenClaw Production Baseline"
oc_version="$(openclaw --version 2>/dev/null | head -n 1 || true)"
if [[ -n "$oc_version" ]]; then
    pass "OpenClaw Version" "$oc_version"
else
    fail "OpenClaw Version" "Unable to determine version"
fi

if openclaw status --all >/dev/null 2>&1; then
    pass "OpenClaw Configuration" "Configuration is valid"
else
    fail "OpenClaw Configuration" "Configuration/status check failed"
fi

if [[ -f "$HOME/.openclaw/openclaw.json" ]] &&
   python3 - "$HOME/.openclaw/openclaw.json" <<'PY' >/dev/null 2>&1
import json
import sys

with open(sys.argv[1], encoding="utf-8") as handle:
    data = json.load(handle)

memory = data.get("memory", {})
assert not memory.get("cloud", {}).get("enabled", False)
PY
then
    pass "OpenClaw Memory Search" "Cloud memory search disabled"
else
    warn "OpenClaw Memory Search" \
        "Unable to confirm cloud memory search is disabled"
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

assert data.get("agents", {}).get("defaults", {}).get("sandbox", {}).get("mode") == "all"
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

print_section "Qdrant Production Baseline"
if [[ -f "$QDRANT_COMPOSE_FILE" ]]; then
    pass "Qdrant Compose" "Present: $QDRANT_COMPOSE_FILE"
else
    fail "Qdrant Compose" "Missing: $QDRANT_COMPOSE_FILE"
fi

q_image="$(docker inspect "$QDRANT_CONTAINER" --format '{{.Config.Image}}' 2>/dev/null || true)"
if [[ "$q_image" == "$EXPECTED_QDRANT_IMAGE" ]]; then
    pass "Qdrant Image" "Pinned: $q_image"
else
    fail "Qdrant Image" "Expected $EXPECTED_QDRANT_IMAGE; got ${q_image:-missing}"
fi

q_version="$(curl --fail --silent --show-error "$QDRANT_URL" 2>/dev/null |
    python3 -c 'import json,sys; print(json.load(sys.stdin).get("version", ""))' 2>/dev/null || true)"
if [[ "$q_version" == "$EXPECTED_QDRANT_VERSION" ]]; then
    pass "Qdrant Version" "Qdrant $q_version"
else
    fail "Qdrant Version" "Expected $EXPECTED_QDRANT_VERSION; got ${q_version:-unknown}"
fi

q_restart="$(docker inspect "$QDRANT_CONTAINER" --format '{{.HostConfig.RestartPolicy.Name}}' 2>/dev/null || true)"
if [[ "$q_restart" == "always" ]]; then
    pass "Qdrant Restart Policy" "restart=always"
else
    fail "Qdrant Restart Policy" "Expected always; got ${q_restart:-unknown}"
fi

mounts="$(docker inspect "$QDRANT_CONTAINER" --format '{{range .Mounts}}{{println .Type .Name .Source .Destination}}{{end}}' 2>/dev/null || true)"
if printf '%s\n' "$mounts" | grep -Eq \
    '^volume personal-ai-qdrant-storage .* /qdrant/storage$'; then
    pass "Qdrant Data Mount" \
        "Named volume ${QDRANT_VOLUME} mounted at /qdrant/storage"
else
    fail "Qdrant Data Mount" "Expected named-volume mount not found"
fi

if printf '%s\n' "$mounts" | grep -Eq ' /qdrant/snapshots$'; then
    pass "Qdrant Snapshot Mount" "Host snapshot bind mounted"
else
    fail "Qdrant Snapshot Mount" "Snapshot bind mount not found"
fi

port_bindings="$(docker port "$QDRANT_CONTAINER" 2>/dev/null || true)"
if printf '%s\n' "$port_bindings" | grep -Fx \
       '6333/tcp -> 127.0.0.1:6333' >/dev/null 2>&1 &&
   printf '%s\n' "$port_bindings" | grep -Fx \
       '6334/tcp -> 127.0.0.1:6334' >/dev/null 2>&1; then
    pass "Qdrant Network Binding" \
        "REST and gRPC are loopback-only"
else
    fail "Qdrant Network Binding" \
        "Expected loopback-only bindings were not confirmed"
fi

metadata="$(curl --fail --silent --show-error \
    "${QDRANT_URL}/collections/${QDRANT_COLLECTION}" 2>/dev/null || true)"
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
        fail "Qdrant Vector Contract" "Contract mismatch"
    fi
else
    fail "Qdrant Collection" "Unable to inspect ${QDRANT_COLLECTION}"
    fail "Qdrant Point Count" "Collection unavailable"
    fail "Qdrant Vector Contract" "Collection unavailable"
fi

if [[ -x "$QDRANT_PERSISTENCE_TEST" ]]; then
    if "$QDRANT_PERSISTENCE_TEST" >/dev/null 2>&1; then
        pass "Qdrant Persistence Contract" \
            "Collection, payload, vector, and semantic ranking validated"
    else
        fail "Qdrant Persistence Contract" \
            "Persistence validation script failed"
    fi
else
    fail "Qdrant Persistence Contract" \
        "Test unavailable: $QDRANT_PERSISTENCE_TEST"
fi

print_section "Summary"
DURATION=$(( $(date +%s) - START_TIME ))
TOTAL=$((PASS_COUNT + WARN_COUNT + FAIL_COUNT))
printf 'Checks   : %s\n' "$TOTAL"
printf 'Passed   : %s\n' "$PASS_COUNT"
printf 'Warnings : %s\n' "$WARN_COUNT"
printf 'Failed   : %s\n' "$FAIL_COUNT"
printf 'Duration : %ss\n' "$DURATION"

if [[ "$FAIL_COUNT" -eq 0 ]]; then
    printf 'Overall  : PASS\n'
    print_success "Platform verification PASSED"
    exit 0
fi

printf 'Overall  : FAIL\n'
print_error "Platform verification FAILED"
exit 1
