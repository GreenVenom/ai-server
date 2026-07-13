#!/bin/bash

############################################################
#
# Foundation Profile
#
############################################################

PROFILE_ID="foundation"
PROFILE_NAME="Foundation"

REQUIRED_COMMANDS=(
    git
    ssh
)

REQUIRED_SERVICES=(
    Tailscale
)

REQUIRED_DIRECTORIES=(
    "$SERVER_ROOT"
    "$CONFIG_DIR"
    "$DATA_DIR"
    "$LOG_DIR"
    "$BACKUP_DIR"
)

REQUIRED_MODELS=()

REQUIRED_APIS=()

MIN_MEMORY_GB=8
MIN_DISK_GB=10