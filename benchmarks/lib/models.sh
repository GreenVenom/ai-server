#!/bin/bash

############################################################
#
# Personal AI Platform
#
# Benchmark Framework
#
# Script: models.sh
#
# Purpose:
# Model discovery and validation utilities.
#
# Version: 1.0.0
#
############################################################

[[ -n "${BENCHMARK_MODELS_LOADED:-}" ]] && return
BENCHMARK_MODELS_LOADED=1

############################################################
# Dependencies
############################################################

source "$(dirname "${BASH_SOURCE[0]}")/constants.sh"

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

############################################################
# Validation
############################################################

ollama_available() {

    command -v ollama >/dev/null 2>&1

}

############################################################
# Installed Models
############################################################

installed_models() {

    ollama list 2>/dev/null | awk 'NR>1 {print $1}'

}

############################################################
# Model Exists
############################################################

model_exists() {

    local model="$1"

    installed_models | grep -Fxq "$model"

}

############################################################
# Model Count
############################################################

model_count() {

    installed_models | wc -l | tr -d ' '

}

############################################################
# Default Models
############################################################

recommended_models() {

cat <<EOF
qwen3:14b
gemma4:12b
nomic-embed-text
EOF

}

############################################################
# Missing Models
############################################################

missing_models() {

    while read -r model
    do
        model_exists "$model" || echo "$model"
    done < <(recommended_models)

}

############################################################
# Installed Recommended Models
############################################################

installed_recommended_models() {

    while read -r model
    do
        model_exists "$model" && echo "$model"
    done < <(recommended_models)

}

############################################################
# Verify Recommended Models
############################################################

verify_models() {

    local missing

    missing=$(missing_models)

    [[ -z "$missing" ]]

}

############################################################
# Pull Model
############################################################

pull_model() {

    local model="$1"

    ollama pull "$model"

}

############################################################
# Remove Model
############################################################

remove_model() {

    local model="$1"

    ollama rm "$model"

}

############################################################
# Model Size
############################################################

model_size() {

    local model="$1"

    ollama list | awk -v m="$model" '$1==m {print $2}'

}

############################################################
# Model Metadata
############################################################

model_metadata() {

    local model="$1"

    ollama show "$model"

}

############################################################
# Pretty Printing
############################################################

print_models() {

    echo

    echo "Installed Models"

    echo "----------------"

    installed_models

    echo

}