#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/../lib/config.sh"
source "$SCRIPT_DIR/../lib/common.sh"

header "Models"

INSTALLED=$(ollama list)

for MODEL in "${REQUIRED_MODELS[@]}"
do
    if echo "$INSTALLED" | grep -q "$MODEL"
    then
        pass "$MODEL"
    else
        warn "$MODEL"
    fi
done

summary