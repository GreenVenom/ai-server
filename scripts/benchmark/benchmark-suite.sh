#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/../lib/config.sh"

for MODEL in "${REQUIRED_MODELS[@]}"
do

    if [[ "$MODEL" == "nomic-embed-text" ]]
    then
        continue
    fi

    "$SCRIPT_DIR/benchmark-model.sh" "$MODEL"

    echo

done