#!/bin/bash

############################################################
#
# Personal AI Platform
#
# Script: logging.sh
#
############################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="${SCRIPT_DIR}/../logs"

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