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
# Version: 1.0.0
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

print_header "Platform Status"

echo "Platform : $PLATFORM_VERSION"
echo "Hostname : $(get_hostname)"
echo

execute_check check_service "Ollama" ollama_running
execute_check check_service "Docker" docker_running
execute_check check_service "Tailscale" tailscale_running

echo

execute_check check_api "Ollama API" "http://${OLLAMA_HOST}/api/version"

echo

echo "Installed Models"

if ollama_installed; then
    ollama list
else
    echo "Ollama not installed."
fi

echo

echo "Disk Free : $(get_disk_free)"
echo "Memory    : $(get_memory_gb) GB"

echo

echo "Overall Status : $(overall_status)"