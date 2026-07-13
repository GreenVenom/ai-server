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

print_header "Production Verification"

############################################################
# Required Commands
############################################################

execute_check check_command git
execute_check check_command ollama
execute_check check_command docker

############################################################
# Required Services
############################################################

execute_check check_service "Ollama" ollama_running
execute_check check_service "Tailscale" tailscale_running

############################################################
# Required API
############################################################

execute_check check_api "Ollama API" \
"http://${OLLAMA_HOST}/api/version"

############################################################
# Required Directories
############################################################

execute_check check_directory "Server Root" "$SERVER_ROOT"
execute_check check_directory "Models" "$MODEL_DIR"

############################################################
# Required Models
############################################################

execute_check check_model "nomic-embed-text"

############################################################
# Final Verification
############################################################

print_summary

if [[ "$FAIL_COUNT" -eq 0 ]]; then
    print_success "Platform verification PASSED"
    exit 0
fi

print_error "Platform verification FAILED"
exit 1