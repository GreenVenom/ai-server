#!/bin/bash

############################################################
#
# Personal AI Platform
#
# Script: doctor.sh
#
# Purpose:
# Comprehensive platform diagnostics.
#
# Version: 3.0.0
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

print_header "$PLATFORM_NAME"

echo "Platform Version   : $PLATFORM_VERSION"
echo "Operations Version : $OPERATIONS_VERSION"
echo "Hostname           : $(get_hostname)"
echo

print_section "Platform"

echo "macOS        : $(get_macos_version)"
echo "Build        : $(get_build_version)"
echo "Architecture : $(get_architecture)"
echo "CPU          : $(get_cpu)"
echo "Memory       : $(get_memory_gb) GB"
echo "Disk Free    : $(get_disk_free)"

print_section "Installed Commands"

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
execute_check check_openclaw_loopback

print_section "Directories"

execute_check check_directory "Server Root" "$SERVER_ROOT"
execute_check check_directory "Configuration" "$CONFIG_DIR"
execute_check check_directory "Data" "$DATA_DIR"
execute_check check_directory "Logs" "$LOG_DIR"
execute_check check_directory "Backups" "$BACKUP_DIR"
execute_check check_directory "Models" "$MODEL_DIR"
execute_check check_writable_directory "OpenClaw Main Workspace" "$OPENCLAW_WORKSPACE"

print_section "APIs"

execute_check check_api "Ollama API" "http://${OLLAMA_HOST}/api/version"
execute_check check_port "OpenClaw Gateway Port" "$OPENCLAW_GATEWAY_HOST" "$OPENCLAW_GATEWAY_PORT"

print_section "Models"

execute_check check_model "nomic-embed-text"
execute_check check_model "gemma4:12b"
execute_check check_model "qwen3:14b"
execute_check check_openclaw_models

print_section "OpenClaw"

execute_check check_openclaw_version
execute_check check_openclaw_config
execute_check check_openclaw_memory_search
execute_check check_openclaw_docker_socket
execute_check check_openclaw_sandbox_image
execute_check check_openclaw_sandbox_policy
execute_check check_openclaw_sandbox_runtime
execute_check check_openclaw_security

print_summary

log_info "doctor.sh completed with status $(overall_status)."
