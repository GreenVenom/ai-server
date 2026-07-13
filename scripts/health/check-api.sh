#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/../lib/config.sh"
source "$SCRIPT_DIR/../lib/common.sh"

header "API"

RESPONSE=$(curl -fs "$OLLAMA_URL/api/version")

if [[ $? -ne 0 ]]; then
    fail "API unavailable"
    summary
    exit 1
fi

VERSION=$(echo "$RESPONSE" | sed -n 's/.*"version":"\([^"]*\)".*/\1/p')

pass "API reachable"

info "Version: $VERSION"

summary