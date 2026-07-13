#!/bin/bash

############################################################
#
# Milestone 01
#
############################################################

PROFILE_ID="m01"
PROFILE_NAME="Milestone 01"

REQUIRED_COMMANDS=(
    git
    ssh
    docker
)

REQUIRED_SERVICES=(
    Docker
    Tailscale
)

REQUIRED_DIRECTORIES=(
    "$SERVER_ROOT"
    "$CONFIG_DIR"
    "$DATA_DIR"
    "$LOG_DIR"
    "$BACKUP_DIR"
    "$MODEL_DIR"
)

REQUIRED_MODELS=()

REQUIRED_APIS=()

MIN_MEMORY_GB=24
MIN_DISK_GB=20