#!/bin/bash

############################################################
#
# Personal AI Platform
#
# Benchmark Framework
#
# Script: results.sh
#
# Purpose:
#
# Implements the Benchmark Result Repository.
#
# This library owns every benchmark result generated during
# a benchmark session.
#
# Responsibilities
#
#   • Result lifecycle
#   • Repository management
#   • Result validation
#   • Result lookup
#   • Result iteration
#
# Serialization is intentionally implemented later in this
# file to keep the data model separate from persistence.
#
# Version: 2.0.0
#
############################################################

[[ -n "${BENCHMARK_RESULTS_LOADED:-}" ]] && return
BENCHMARK_RESULTS_LOADED=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${SCRIPT_DIR}/constants.sh"

############################################################
# Repository
############################################################

#
# Associative array storing every field.
#
# Keys use:
#
#     <ResultID>:<FieldName>
#
# Example:
#
#     result-000001:model
#     result-000001:provider
#     result-000001:duration_ms
#
#

declare -Ag RESULT_REPOSITORY

#
# Ordered list of Result IDs.
#

declare -ag RESULT_IDS

############################################################
# Repository Metadata
############################################################

RESULT_REPOSITORY_VERSION="2.0"

RESULT_COUNT=0

############################################################
# Repository Lifecycle
############################################################

results_reset() {

    RESULT_REPOSITORY=()

    RESULT_IDS=()

    RESULT_COUNT=0

}

############################################################

results_count() {

    echo "${RESULT_COUNT}"

}

############################################################

results_empty() {

    [[ ${RESULT_COUNT} -eq 0 ]]

}

############################################################
# Result Creation
############################################################

result_create() {

    RESULT_COUNT=$((RESULT_COUNT + 1))

    local id

    id=$(printf "result-%06d" "${RESULT_COUNT}")

    RESULT_IDS+=("${id}")

    RESULT_REPOSITORY["${id}:created"]=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    echo "${id}"

}

############################################################
# Repository Queries
############################################################

results_ids() {

    printf "%s\n" "${RESULT_IDS[@]}"

}

############################################################

results_exists() {

    local id="$1"

    [[ " ${RESULT_IDS[*]} " == *" ${id} "* ]]

}

############################################################

results_first() {

    [[ ${#RESULT_IDS[@]} -eq 0 ]] && return 1

    echo "${RESULT_IDS[0]}"

}

############################################################

results_last() {

    [[ ${#RESULT_IDS[@]} -eq 0 ]] && return 1

    echo "${RESULT_IDS[-1]}"

}

############################################################
# Field Access
############################################################

result_set() {

    local id="$1"

    local field="$2"

    local value="$3"

    RESULT_REPOSITORY["${id}:${field}"]="${value}"

}

############################################################

result_get() {

    local id="$1"

    local field="$2"

    echo "${RESULT_REPOSITORY["${id}:${field}"]}"

}

############################################################

result_has() {

    local id="$1"

    local field="$2"

    [[ -n "${RESULT_REPOSITORY["${id}:${field}"]+x}" ]]

}

############################################################

result_remove() {

    local id="$1"

    local field="$2"

    unset RESULT_REPOSITORY["${id}:${field}"]

}

############################################################
# Convenience Setters
############################################################

result_set_provider() {

    result_set "$1" provider "$2"

}

result_set_model() {

    result_set "$1" model "$2"

}

result_set_profile() {

    result_set "$1" profile "$2"

}

result_set_workload() {

    result_set "$1" workload "$2"

}

result_set_prompt() {

    result_set "$1" prompt "$2"

}

result_set_duration_ms() {

    result_set "$1" duration_ms "$2"

}

result_set_duration_seconds() {

    result_set "$1" duration_seconds "$2"

}

result_set_tokens() {

    result_set "$1" tokens "$2"

}

result_set_tokens_per_second() {

    result_set "$1" tokens_per_second "$2"

}

result_set_memory_mb() {

    result_set "$1" memory_mb "$2"

}

result_set_cpu_percent() {

    result_set "$1" cpu_percent "$2"

}

result_set_output() {

    result_set "$1" output "$2"

}

result_set_timestamp() {

    result_set "$1" timestamp "$2"

}

############################################################
# Convenience Getters
############################################################

result_provider() {

    result_get "$1" provider

}

result_model() {

    result_get "$1" model

}

result_profile() {

    result_get "$1" profile

}

result_workload() {

    result_get "$1" workload

}

result_prompt() {

    result_get "$1" prompt

}

result_duration_ms() {

    result_get "$1" duration_ms

}

result_duration_seconds() {

    result_get "$1" duration_seconds

}

result_tokens() {

    result_get "$1" tokens

}

result_tokens_per_second() {

    result_get "$1" tokens_per_second

}

result_memory_mb() {

    result_get "$1" memory_mb

}

result_cpu_percent() {

    result_get "$1" cpu_percent

}

result_output() {

    result_get "$1" output

}

result_timestamp() {

    result_get "$1" timestamp

}

