#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

MODEL="$1"

if [[ -z "$MODEL" ]]
then
    echo "Usage:"
    echo "./benchmark-model.sh model"
    exit 1
fi

mkdir -p "$SCRIPT_DIR/results"

OUTPUT="$SCRIPT_DIR/results/$(date +%F-%H%M%S)-${MODEL//:/-}.txt"

{

echo "Model: $MODEL"

echo "Date : $(date)"

echo

/usr/bin/time ollama run "$MODEL" "Summarize the purpose of this benchmark in one paragraph."

} | tee "$OUTPUT"

echo

echo "Saved to"

echo "$OUTPUT"