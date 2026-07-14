#!/bin/bash

############################################################
#
# Personal AI Platform
#
# Benchmark Framework
#
# Script: executor.sh
#
# Purpose:
# Execute benchmark jobs against an inference provider.
#
# Responsibilities:
#   - Execute inference requests
#   - Normalize provider output
#   - Capture timing
#   - Capture response metadata
#   - Detect execution failures
#   - Populate benchmark context
#
# Version: 1.0.0
#
############################################################

[[ -n "${BENCHMARK_EXECUTOR_LOADED:-}" ]] && return
BENCHMARK_EXECUTOR_LOADED=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${SCRIPT_DIR}/providers.sh"
source "${SCRIPT_DIR}/timer.sh"
source "${SCRIPT_DIR}/results.sh"
source "${SCRIPT_DIR}/prompts.sh"

############################################################
# Internal State
############################################################

EXECUTOR_EXIT_CODE=0
EXECUTOR_RAW_OUTPUT=""
EXECUTOR_ERROR=""
EXECUTOR_TOKEN_COUNT=0

############################################################
# Reset
############################################################

executor_reset() {

    EXECUTOR_EXIT_CODE=0
    EXECUTOR_RAW_OUTPUT=""
    EXECUTOR_ERROR=""
    EXECUTOR_TOKEN_COUNT=0

}

############################################################
# Execute Benchmark Job
############################################################

executor_execute() {

    executor_reset

    local model="$JOB_MODEL"

    local prompt

    prompt="$(load_prompt "$JOB_WORKLOAD")" || {

        EXECUTOR_ERROR="Unable to load prompt."

        return 1

    }

    timer_start

    EXECUTOR_RAW_OUTPUT="$(
        provider_generate \
            "$model" \
            "$prompt" \
            2>&1
    )"

    EXECUTOR_EXIT_CODE=$?

    timer_stop

    if [[ ${EXECUTOR_EXIT_CODE} -ne 0 ]]; then

        EXECUTOR_ERROR="${EXECUTOR_RAW_OUTPUT}"

        return ${EXECUTOR_EXIT_CODE}

    fi

    executor_collect_metrics

    executor_populate_context

}

############################################################
# Metric Collection
############################################################

executor_collect_metrics() {

    EXECUTOR_TOKEN_COUNT=$(
        printf "%s" "${EXECUTOR_RAW_OUTPUT}" |
        wc -w |
        tr -d ' '
    )

}

############################################################
# Populate Benchmark Context
############################################################

executor_populate_context() {

    BENCHMARK_MODEL="${JOB_MODEL}"

    BENCHMARK_PROVIDER="${JOB_PROVIDER}"

    BENCHMARK_PROFILE="${JOB_PROFILE}"

    BENCHMARK_WORKLOAD="${JOB_WORKLOAD}"

    BENCHMARK_PROMPT="$(basename "${JOB_PROMPT_FILE}")"

    BENCHMARK_DURATION_MS="$(timer_elapsed_ms)"

    BENCHMARK_DURATION_SECONDS="$(timer_elapsed_seconds)"

    BENCHMARK_TOKENS="${EXECUTOR_TOKEN_COUNT}"

    BENCHMARK_TOKENS_PER_SECOND="$(
        statistics_tokens_per_second \
            "${EXECUTOR_TOKEN_COUNT}" \
            "${BENCHMARK_DURATION_SECONDS}"
    )"

    BENCHMARK_OUTPUT="${EXECUTOR_RAW_OUTPUT}"

    BENCHMARK_TIMESTAMP="$(iso_timestamp)"

}

############################################################
# Status
############################################################

executor_success() {

    [[ ${EXECUTOR_EXIT_CODE} -eq 0 ]]

}

executor_failure() {

    [[ ${EXECUTOR_EXIT_CODE} -ne 0 ]]

}

############################################################
# Accessors
############################################################

executor_output() {

    printf "%s\n" "${EXECUTOR_RAW_OUTPUT}"

}

executor_error() {

    printf "%s\n" "${EXECUTOR_ERROR}"

}

############################################################
# Summary
############################################################

executor_summary() {

cat <<EOF

Executor Summary
----------------

Provider : ${JOB_PROVIDER}
Model    : ${JOB_MODEL}
Workload : ${JOB_WORKLOAD}
Duration : ${BENCHMARK_DURATION_SECONDS}s
Tokens   : ${BENCHMARK_TOKENS}
Tok/sec  : ${BENCHMARK_TOKENS_PER_SECOND}

EOF

}