#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/../lib/config.sh"
source "$SCRIPT_DIR/../lib/common.sh"

header "Storage"

[[ -d "$MODEL_DIR" ]] \
    && pass "Model directory exists." \
    || fail "Model directory missing."

[[ -w "$MODEL_DIR" ]] \
    && pass "Directory writable." \
    || fail "Directory not writable."

AVAILABLE=$(df -Pk "$MODEL_DIR" | awk 'NR==2 {print $4}')

AVAILABLE_GB=$((AVAILABLE / 1024 / 1024))

if [[ $AVAILABLE_GB -lt 20 ]]; then
    warn "Less than 20 GB free."
else
    pass "${AVAILABLE_GB} GB available."
fi

summary