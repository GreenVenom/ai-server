#!/bin/bash

############################################################
#
# Milestone 02
#
############################################################

PROFILE_ID="m02"
PROFILE_NAME="Milestone 02"

REQUIRED_COMMANDS=(
    git
    docker
    ollama
)

REQUIRED_SERVICES=(
    Ollama
    Docker
    Tailscale
)

REQUIRED_DIRECTORIES=(
    "$SERVER_ROOT"
    "$CONFIG_DIR"
    "$DATA_DIR"
    "$MODEL_DIR"
    "$LOG_DIR"
    "$BACKUP_DIR"
)

REQUIRED_MODELS=(
    nomic-embed-text
)

REQUIRED_APIS=(
    "http://${OLLAMA_HOST}/api/version"
)

MIN_MEMORY_GB=24
MIN_DISK_GB=20