#!/usr/bin/env bash
#
# ============================================================
# Personal AI Platform
# Benchmark Framework
#
# File: prompts.sh
#
# Purpose:
#   Provides framework-level prompt and workload access.
#
# Responsibilities:
#   - Workload discovery
#   - Prompt file resolution
#   - Prompt loading
#   - Expected-output file resolution
#   - Workload descriptions
#   - Workload timeout lookup
#   - Prompt validation
#
# Design:
#   - Uses definitions.sh as the workload specification
#   - Reads prompt files from benchmarks/prompts/
#   - Reads optional expected files from benchmarks/expected/
#   - Does not execute providers or benchmarks
#
# Compatibility:
#   - Bash 3.2+
# ============================================================

[[ -n "${BENCHMARK_PROMPTS_LOADED:-}" ]] && return 0
BENCHMARK_PROMPTS_LOADED=1

PROMPTS_API_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROMPTS_LIB_DIR="$(cd "${PROMPTS_API_DIR}/.." && pwd)"
PROMPTS_BENCHMARKS_DIR="$(cd "${PROMPTS_LIB_DIR}/.." && pwd)"
PROMPTS_CORE_DIR="${PROMPTS_LIB_DIR}/core"

PROMPTS_DIR="${PROMPTS_BENCHMARKS_DIR}/prompts"
EXPECTED_DIR="${PROMPTS_BENCHMARKS_DIR}/expected"

# shellcheck source=/dev/null
source "${PROMPTS_CORE_DIR}/definitions.sh"

# shellcheck source=/dev/null
source "${PROMPTS_CORE_DIR}/validators.sh"

# ------------------------------------------------------------
# Workload metadata
# ------------------------------------------------------------

workload_description() {
    local workload="$1"

    workload_valid "$workload" || return "$EXIT_WORKLOAD_NOT_FOUND"

    case "$workload" in
        "$WORKLOAD_REASONING")
            printf "%s\n" "Reasoning and multi-step problem solving"
            ;;
        "$WORKLOAD_CODING")
            printf "%s\n" "Code generation and implementation"
            ;;
        "$WORKLOAD_SUMMARIZATION")
            printf "%s\n" "Text summarization"
            ;;
        "$WORKLOAD_EXTRACTION")
            printf "%s\n" "Structured information extraction"
            ;;
        "$WORKLOAD_CLASSIFICATION")
            printf "%s\n" "Categorization and classification"
            ;;
        "$WORKLOAD_CREATIVE")
            printf "%s\n" "Creative long-form generation"
            ;;
        "$WORKLOAD_EMBEDDING")
            printf "%s\n" "Embedding vector generation"
            ;;
        *)
            return "$EXIT_WORKLOAD_NOT_FOUND"
            ;;
    esac
}

workload_timeout() {
    local workload="$1"

    workload_valid "$workload" || return "$EXIT_WORKLOAD_NOT_FOUND"

    case "$workload" in
        "$WORKLOAD_REASONING")
            printf "%s\n" "120"
            ;;
        "$WORKLOAD_CODING")
            printf "%s\n" "180"
            ;;
        "$WORKLOAD_SUMMARIZATION")
            printf "%s\n" "120"
            ;;
        "$WORKLOAD_EXTRACTION")
            printf "%s\n" "120"
            ;;
        "$WORKLOAD_CLASSIFICATION")
            printf "%s\n" "120"
            ;;
        "$WORKLOAD_CREATIVE")
            printf "%s\n" "300"
            ;;
        "$WORKLOAD_EMBEDDING")
            printf "%s\n" "120"
            ;;
        *)
            printf "%s\n" "$DEFAULT_TIMEOUT_SECONDS"
            ;;
    esac
}

# ------------------------------------------------------------
# Prompt path resolution
# ------------------------------------------------------------

prompt_file() {
    local workload="$1"

    workload_valid "$workload" || return "$EXIT_WORKLOAD_NOT_FOUND"

    printf "%s/%s.txt\n" "$PROMPTS_DIR" "$workload"
}

expected_file() {
    local workload="$1"

    workload_valid "$workload" || return "$EXIT_WORKLOAD_NOT_FOUND"

    printf "%s/%s.txt\n" "$EXPECTED_DIR" "$workload"
}

prompt_exists() {
    local workload="$1"
    local file

    file="$(prompt_file "$workload")" || return 1
    [ -f "$file" ] && [ -s "$file" ]
}

expected_exists() {
    local workload="$1"
    local file

    file="$(expected_file "$workload")" || return 1
    [ -f "$file" ] && [ -s "$file" ]
}

# ------------------------------------------------------------
# Prompt loading
# ------------------------------------------------------------

prompt_load() {
    local workload="$1"
    local file

    file="$(prompt_file "$workload")" || return "$EXIT_WORKLOAD_NOT_FOUND"

    if [ ! -f "$file" ]; then
        return "$EXIT_FAILURE"
    fi

    cat "$file"
}

expected_load() {
    local workload="$1"
    local file

    file="$(expected_file "$workload")" || return "$EXIT_WORKLOAD_NOT_FOUND"

    if [ ! -f "$file" ]; then
        return "$EXIT_FAILURE"
    fi

    cat "$file"
}

# ------------------------------------------------------------
# Workload discovery
# ------------------------------------------------------------

workloads_list() {
    local workload

    for workload in "${WORKLOAD_ENUM[@]}"; do
        printf "%s\n" "$workload"
    done
}

workloads_with_prompts() {
    local workload

    for workload in "${WORKLOAD_ENUM[@]}"; do
        prompt_exists "$workload" && printf "%s\n" "$workload"
    done
}

workloads_missing_prompts() {
    local workload

    for workload in "${WORKLOAD_ENUM[@]}"; do
        prompt_exists "$workload" || printf "%s\n" "$workload"
    done
}

# ------------------------------------------------------------
# Validation
# ------------------------------------------------------------

prompt_validate() {
    local workload="$1"
    local prompt

    workload_valid "$workload" || return 1
    prompt_exists "$workload" || return 1

    prompt="$(prompt_load "$workload")" || return 1
    [ -n "$prompt" ]
}

prompts_validate_all() {
    local workload

    for workload in "${WORKLOAD_ENUM[@]}"; do
        if [ "$workload" = "$WORKLOAD_EMBEDDING" ]; then
            # Embedding workloads may reuse another text fixture later.
            continue
        fi

        prompt_validate "$workload" || return 1
    done

    return 0
}
