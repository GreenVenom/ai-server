#!/bin/bash

############################################################
#
# Personal AI Platform
#
# Script: services.sh
#
# Purpose:
# Service discovery and status.
#
# Version: 2.0.0
#
############################################################

OPENCLAW_GATEWAY_LABEL="${OPENCLAW_GATEWAY_LABEL:-ai.openclaw.gateway}"
OPENCLAW_GATEWAY_HOST="${OPENCLAW_GATEWAY_HOST:-127.0.0.1}"
OPENCLAW_GATEWAY_PORT="${OPENCLAW_GATEWAY_PORT:-18789}"
OPENCLAW_CONFIG_FILE="${OPENCLAW_CONFIG_FILE:-$HOME/.openclaw/openclaw.json}"
OPENCLAW_ENV_FILE="${OPENCLAW_ENV_FILE:-$HOME/.openclaw/.env}"
OPENCLAW_WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/server/workspaces/main}"
OPENCLAW_SANDBOX_IMAGE="${OPENCLAW_SANDBOX_IMAGE:-openclaw-sandbox:bookworm-slim}"
OPENCLAW_PRIMARY_MODEL="${OPENCLAW_PRIMARY_MODEL:-ollama/gemma4:12b}"
OPENCLAW_FALLBACK_MODEL="${OPENCLAW_FALLBACK_MODEL:-ollama/qwen3:14b}"
OPENCLAW_DOCKER_SOCKET="${OPENCLAW_DOCKER_SOCKET:-$HOME/.docker/run/docker.sock}"

############################################################
# Ollama
############################################################

ollama_installed() {
    command -v ollama >/dev/null 2>&1
}

ollama_running() {
    pgrep -x ollama >/dev/null 2>&1
}

ollama_version() {
    ollama --version 2>/dev/null
}

############################################################
# Docker
############################################################

docker_installed() {
    command -v docker >/dev/null 2>&1
}

docker_running() {
    docker info >/dev/null 2>&1
}

docker_version() {
    docker --version 2>/dev/null
}

docker_socket_available() {
    [[ -S "$OPENCLAW_DOCKER_SOCKET" ]]
}

docker_sandbox_image_available() {
    docker image inspect "$OPENCLAW_SANDBOX_IMAGE" >/dev/null 2>&1
}

############################################################
# Tailscale
############################################################

tailscale_installed() {
    command -v tailscale >/dev/null 2>&1
}

tailscale_running() {
    pgrep tailscaled >/dev/null 2>&1
}

############################################################
# Git
############################################################

git_installed() {
    command -v git >/dev/null 2>&1
}

git_version() {
    git --version 2>/dev/null
}

############################################################
# OpenClaw
############################################################

openclaw_installed() {
    command -v openclaw >/dev/null 2>&1
}

openclaw_version() {
    openclaw --version 2>/dev/null
}

openclaw_launchagent_loaded() {
    launchctl print "gui/$(id -u)/${OPENCLAW_GATEWAY_LABEL}" >/dev/null 2>&1
}

openclaw_running() {
    openclaw_launchagent_loaded || return 1

    openclaw gateway status 2>/dev/null |
        grep -Eq 'Runtime:[[:space:]]+running|state active'
}

openclaw_gateway_reachable() {
    openclaw gateway status 2>/dev/null |
        grep -Eq 'Connectivity probe:[[:space:]]+ok|reachable'
}

openclaw_gateway_loopback_only() {
    local output

    output="$(openclaw gateway status 2>/dev/null)" || return 1

    printf '%s\n' "$output" |
        grep -Eq 'bind=loopback|127\.0\.0\.1'

    if printf '%s\n' "$output" |
        grep -Eq 'bind=(lan|tailnet|custom)|0\.0\.0\.0'; then
        return 1
    fi

    return 0
}

openclaw_config_valid() {
    openclaw config validate >/dev/null 2>&1
}

openclaw_primary_model() {
    openclaw models status 2>/dev/null |
        awk -F: '/^Default[[:space:]]*:/ {
            sub(/^[[:space:]]+/, "", $2)
            print $2
            exit
        }'
}

openclaw_fallback_models() {
    openclaw models status 2>/dev/null |
        awk -F: '/^Fallbacks/ {
            sub(/^[[:space:]]+/, "", $2)
            print $2
            exit
        }'
}

openclaw_primary_model_correct() {
    [[ "$(openclaw_primary_model)" == "$OPENCLAW_PRIMARY_MODEL" ]]
}

openclaw_fallback_model_correct() {
    openclaw_fallback_models |
        grep -Fq "$OPENCLAW_FALLBACK_MODEL"
}

openclaw_workspace_configured() {
    local configured

    configured="$(openclaw config get agents.defaults.workspace 2>/dev/null)" ||
        return 1

    [[ "$configured" == "$OPENCLAW_WORKSPACE" ]]
}

openclaw_workspace_available() {
    [[ -d "$OPENCLAW_WORKSPACE" && -r "$OPENCLAW_WORKSPACE" && -w "$OPENCLAW_WORKSPACE" ]]
}

openclaw_sandbox_explain() {
    openclaw sandbox explain --agent main 2>/dev/null
}

openclaw_sandbox_mode_all() {
    openclaw_sandbox_explain |
        grep -Eq 'mode:[[:space:]]+all'
}

openclaw_sandbox_workspace_rw() {
    local output

    output="$(openclaw_sandbox_explain)" || return 1

    printf '%s\n' "$output" |
        grep -Eq 'workspaceAccess:[[:space:]]+rw'

    printf '%s\n' "$output" |
        grep -Fq "$OPENCLAW_WORKSPACE -> /workspace rw"
}

openclaw_elevated_disabled() {
    openclaw_sandbox_explain |
        grep -Eq 'enabled:[[:space:]]+false'
}

openclaw_web_tools_disabled() {
    local denied

    denied="$(openclaw config get tools.deny 2>/dev/null)" || return 1

    printf '%s\n' "$denied" | grep -Fq 'group:web' &&
        printf '%s\n' "$denied" | grep -Fq 'browser'
}

openclaw_memory_search_disabled() {
    local enabled

    enabled="$(openclaw config get agents.defaults.memorySearch.enabled 2>/dev/null)" ||
        return 1

    [[ "$enabled" == "false" ]]
}

openclaw_docker_socket_configured() {
    [[ -f "$OPENCLAW_ENV_FILE" ]] || return 1

    grep -Fxq \
        "OPENCLAW_DOCKER_SOCKET=$OPENCLAW_DOCKER_SOCKET" \
        "$OPENCLAW_ENV_FILE"
}

openclaw_security_audit_output() {
    openclaw security audit --deep 2>/dev/null
}

openclaw_security_critical_count() {
    local output

    output="$(openclaw_security_audit_output)" || return 1

    printf '%s\n' "$output" |
        sed -n 's/^Summary: \([0-9][0-9]*\) critical.*/\1/p' |
        head -n 1
}

openclaw_security_no_critical() {
    local count

    count="$(openclaw_security_critical_count)" || return 1

    [[ "$count" == "0" ]]
}

openclaw_sandbox_runtime_running() {
    openclaw sandbox list 2>/dev/null |
        grep -Eq 'Total: [1-9][0-9]* \([1-9][0-9]* running\)|Status:.*running'
}

############################################################
# Future Components
############################################################

qdrant_running() {
    return 1
}
