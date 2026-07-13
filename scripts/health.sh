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

print_header "Platform Health"

############################################################
# Commands
############################################################

execute_check check_command git
execute_check check_command docker
execute_check check_command ollama

############################################################
# Services
############################################################

execute_check check_service "Ollama" ollama_running
execute_check check_service "Docker" docker_running
execute_check check_service "Tailscale" tailscale_running

############################################################
# Directories
############################################################

execute_check check_directory "Server Root" "$SERVER_ROOT"
execute_check check_directory "Configuration" "$CONFIG_DIR"
execute_check check_directory "Data" "$DATA_DIR"
execute_check check_directory "Logs" "$LOG_DIR"
execute_check check_directory "Backups" "$BACKUP_DIR"
execute_check check_directory "Models" "$MODEL_DIR"

############################################################
# Resources
############################################################

execute_check check_memory 24

execute_check check_disk_space "$SERVER_ROOT" 20

############################################################
# API
############################################################

execute_check check_api "Ollama API" \
"http://${OLLAMA_HOST}/api/version"

############################################################
# Models
############################################################

execute_check check_model "nomic-embed-text"

############################################################
# Summary
############################################################

print_summary

log_info "health.sh completed."