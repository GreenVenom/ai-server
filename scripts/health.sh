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

print_header "Platform Health"

print_section "Commands"

execute_check check_command git
execute_check check_command docker
execute_check check_command ollama
execute_check check_command openclaw

print_section "Services"

execute_check check_service "Ollama" ollama_running
execute_check check_service "Docker" docker_running
execute_check check_service "Tailscale" tailscale_running
execute_check check_openclaw_gateway
execute_check check_openclaw_rpc

print_section "Directories"

execute_check check_directory "Server Root" "$SERVER_ROOT"
execute_check check_directory "Configuration" "$CONFIG_DIR"
execute_check check_directory "Data" "$DATA_DIR"
execute_check check_directory "Logs" "$LOG_DIR"
execute_check check_directory "Backups" "$BACKUP_DIR"
execute_check check_directory "Models" "$MODEL_DIR"
execute_check check_openclaw_workspace

print_section "Resources"

execute_check check_memory 24
execute_check check_disk_space "$SERVER_ROOT" 20

print_section "APIs"

execute_check check_api "Ollama API" "http://${OLLAMA_HOST}/api/version"
execute_check check_port "OpenClaw Gateway Port" "$OPENCLAW_GATEWAY_HOST" "$OPENCLAW_GATEWAY_PORT"

print_section "Models"

execute_check check_model "nomic-embed-text"
execute_check check_model "gemma4:12b"
execute_check check_model "qwen3:14b"
execute_check check_openclaw_models

print_section "OpenClaw Health"

execute_check check_openclaw_config
execute_check check_openclaw_loopback
execute_check check_openclaw_docker_socket
execute_check check_openclaw_sandbox_image
execute_check check_openclaw_sandbox_policy
execute_check check_openclaw_security

print_summary

log_info "health.sh completed with status $(overall_status)."

[[ "$FAIL_COUNT" -eq 0 ]]
