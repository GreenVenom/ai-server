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
# Version: 2.0.0
#
############################################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/lib"

source "${LIB_DIR}/version.sh"
source "${LIB_DIR}/colors.sh"
source "${LIB_DIR}/logging.sh"
source "${LIB_DIR}/common.sh"
source "${LIB_DIR}/platform.sh"
source "${LIB_DIR}/services.sh"
source "${LIB_DIR}/results.sh"
source "${LIB_DIR}/checks.sh"

print_header "Production Verification"

print_section "Required Commands"

execute_check check_command git
execute_check check_command ollama
execute_check check_command docker
execute_check check_command openclaw

print_section "Required Services"

execute_check check_service "Ollama" ollama_running
execute_check check_service "Docker" docker_running
execute_check check_service "Tailscale" tailscale_running
execute_check check_openclaw_gateway
execute_check check_openclaw_rpc
execute_check check_openclaw_loopback

print_section "Required APIs"

execute_check check_api "Ollama API" "http://${OLLAMA_HOST}/api/version"
execute_check check_port "OpenClaw Gateway" "$OPENCLAW_GATEWAY_HOST" "$OPENCLAW_GATEWAY_PORT"

print_section "Required Directories"

execute_check check_directory "Server Root" "$SERVER_ROOT"
execute_check check_directory "Models" "$MODEL_DIR"
execute_check check_openclaw_workspace

print_section "Required Models"

execute_check check_model "nomic-embed-text"
execute_check check_model "gemma4:12b"
execute_check check_model "qwen3:14b"
execute_check check_openclaw_models

print_section "OpenClaw Production Baseline"

execute_check check_openclaw_version
execute_check check_openclaw_config
execute_check check_openclaw_memory_search
execute_check check_openclaw_docker_socket
execute_check check_openclaw_sandbox_image
execute_check check_openclaw_sandbox_policy
execute_check check_openclaw_security

print_summary

if [[ "$FAIL_COUNT" -eq 0 ]]; then
    print_success "Platform verification PASSED"
    log_success "verify.sh passed."
    exit 0
fi

print_error "Platform verification FAILED"
log_error "verify.sh failed with ${FAIL_COUNT} failure(s)."
exit 1
