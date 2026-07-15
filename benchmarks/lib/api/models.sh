#!/usr/bin/env bash
#
# ============================================================
# Personal AI Platform
# Benchmark Framework
#
# File: models.sh
#
# Purpose:
#   Provides framework-level model discovery, normalization,
#   classification, and selection.
#
# Responsibilities:
#   - Model name normalization
#   - Model enumeration through providers.sh
#   - Model existence checks
#   - Generation vs embedding role checks
#   - Preferred model selection
#
# Design:
#   - Does not communicate with providers directly
#   - Depends on providers.sh
#   - Keeps provider-specific transport concerns out of callers
#
# Compatibility:
#   - Bash 3.2+
# ============================================================

[[ -n "${BENCHMARK_MODELS_LOADED:-}" ]] && return 0
BENCHMARK_MODELS_LOADED=1

MODELS_API_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=/dev/null
source "${MODELS_API_DIR}/providers.sh"

# ------------------------------------------------------------
# Framework model preferences
# ------------------------------------------------------------

PREFERRED_GENERATION_MODELS=(
    "qwen3:14b"
    "gemma4:12b"
)

PREFERRED_EMBEDDING_MODELS=(
    "nomic-embed-text"
    "nomic-embed-text:latest"
)

# ------------------------------------------------------------
# Name normalization
# ------------------------------------------------------------

model_normalize() {
    local model="$1"

    [ -n "$model" ] || return "$EXIT_INVALID_ARGUMENT"

    case "$model" in
        *:*)
            printf "%s\n" "$model"
            ;;
        *)
            printf "%s:latest\n" "$model"
            ;;
    esac
}

model_base_name() {
    local model="$1"

    [ -n "$model" ] || return "$EXIT_INVALID_ARGUMENT"

    printf "%s\n" "${model%%:*}"
}

# ------------------------------------------------------------
# Model discovery
# ------------------------------------------------------------

models_list() {
    local provider="${1:-$DEFAULT_PROVIDER}"

    provider_models "$provider"
}

model_exists() {
    local provider="$1"
    local model="$2"

    provider_model_exists "$provider" "$model"
}

# ------------------------------------------------------------
# Role classification
# ------------------------------------------------------------

model_is_embedding() {
    local model="$1"
    local base

    base="$(model_base_name "$model")" || return 1

    case "$base" in
        nomic-embed-text|mxbai-embed-large|all-minilm)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

model_is_generation() {
    local model="$1"

    model_is_embedding "$model" && return 1
    return 0
}

# ------------------------------------------------------------
# Preferred model selection
# ------------------------------------------------------------

model_preferred_generation() {
    local provider="${1:-$DEFAULT_PROVIDER}"
    local model

    for model in "${PREFERRED_GENERATION_MODELS[@]}"; do
        if model_exists "$provider" "$model"; then
            printf "%s\n" "$model"
            return 0
        fi
    done

    while IFS= read -r model; do
        [ -n "$model" ] || continue
        if model_is_generation "$model"; then
            printf "%s\n" "$model"
            return 0
        fi
    done <<EOF
$(models_list "$provider")
EOF

    return "$EXIT_MODEL_NOT_FOUND"
}

model_preferred_embedding() {
    local provider="${1:-$DEFAULT_PROVIDER}"
    local model

    for model in "${PREFERRED_EMBEDDING_MODELS[@]}"; do
        if model_exists "$provider" "$model"; then
            printf "%s\n" "$model"
            return 0
        fi
    done

    while IFS= read -r model; do
        [ -n "$model" ] || continue
        if model_is_embedding "$model"; then
            printf "%s\n" "$model"
            return 0
        fi
    done <<EOF
$(models_list "$provider")
EOF

    return "$EXIT_MODEL_NOT_FOUND"
}

# ------------------------------------------------------------
# Filtered model lists
# ------------------------------------------------------------

models_generation() {
    local provider="${1:-$DEFAULT_PROVIDER}"
    local model

    while IFS= read -r model; do
        [ -n "$model" ] || continue
        model_is_generation "$model" && printf "%s\n" "$model"
    done <<EOF
$(models_list "$provider")
EOF
}

models_embeddings() {
    local provider="${1:-$DEFAULT_PROVIDER}"
    local model

    while IFS= read -r model; do
        [ -n "$model" ] || continue
        model_is_embedding "$model" && printf "%s\n" "$model"
    done <<EOF
$(models_list "$provider")
EOF
}
