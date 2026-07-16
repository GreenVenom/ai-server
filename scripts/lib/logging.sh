#!/bin/bash

############################################################
#
# Personal AI Platform
#
# Script: logging.sh
#
############################################################

LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_ROOT="$(cd "${LIB_DIR}/.." && pwd)"
SERVER_ROOT="$(cd "${SCRIPT_ROOT}/.." && pwd)"

LOG_DIR="${SERVER_ROOT}/logs"
mkdir -p "$LOG_DIR"

LOG_FILE="${LOG_DIR}/operations.log"

timestamp() {
    date +"%Y-%m-%d %H:%M:%S"
}

log() {
    level="$1"
    shift

    echo "$(timestamp) [$level] $*" >> "$LOG_FILE"
}

log_info() {
    log INFO "$@"
}

log_warn() {
    log WARN "$@"
}

log_error() {
    log ERROR "$@"
}

log_success() {
    log SUCCESS "$@"
}