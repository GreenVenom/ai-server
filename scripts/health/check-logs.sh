#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

header "Log Check"

LOG_DIR="$HOME/.ollama/logs"

if [ -d "$LOG_DIR" ]; then
    pass "Log directory exists."
else
    fail "Log directory missing."
    exit 1
fi

find "$LOG_DIR" -type f | tail