#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

header "Runtime Check"

if check_command ollama; then
    pass "Ollama binary found."
else
    fail "Ollama binary missing."
    exit 1
fi

if pgrep -x ollama >/dev/null; then
    pass "Ollama process running."
else
    fail "Ollama process not running."
fi

if launchctl list | grep -q "com.ollama.ollama"; then
    pass "launchd service loaded."
else
    fail "launchd service missing."
fi