#!/bin/bash

############################################################
#
# Production Profile
#
############################################################

PROFILE_ID="production"
PROFILE_NAME="Production"

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
    "$SCRIPT_DIR"
)

REQUIRED_MODELS=(
    nomic-embed-text
    qwen3:14b
    gemma4:12b
)

REQUIRED_APIS=(
    "http://${OLLAMA_HOST}/api/version"
)

MIN_MEMORY_GB=24
MIN_DISK_GB=40