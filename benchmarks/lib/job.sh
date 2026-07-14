#!/bin/bash

############################################################
#
# Personal AI Platform
#
# Benchmark Framework
#
# Script: job.sh
#
# Purpose:
# Benchmark job lifecycle and execution context.
#
# Responsibilities:
#   - Create benchmark jobs
#   - Maintain benchmark state
#   - Validate configuration
#   - Reset execution context
#
# Version: 1.0.0
#
############################################################

[[ -n "${BENCHMARK_JOB_LOADED:-}" ]] && return
BENCHMARK_JOB_LOADED=1

############################################################
# Job Context
############################################################

JOB_ID=""
JOB_TIMESTAMP=""

JOB_PROVIDER=""
JOB_PROFILE=""

JOB_MODEL=""
JOB_WORKLOAD=""

JOB_PROMPT_FILE=""
JOB_EXPECTED_FILE=""

JOB_ITERATIONS=1
JOB_TIMEOUT=60

############################################################
# Lifecycle
############################################################

job_reset() {

    JOB_ID=""
    JOB_TIMESTAMP=""

    JOB_PROVIDER=""
    JOB_PROFILE=""

    JOB_MODEL=""
    JOB_WORKLOAD=""

    JOB_PROMPT_FILE=""
    JOB_EXPECTED_FILE=""

    JOB_ITERATIONS=1
    JOB_TIMEOUT=60

}

############################################################

job_create() {

    local provider="$1"
    local profile="$2"
    local model="$3"
    local workload="$4"

    job_reset

    JOB_PROVIDER="$provider"
    JOB_PROFILE="$profile"

    JOB_MODEL="$model"
    JOB_WORKLOAD="$workload"

    JOB_PROMPT_FILE="${PROMPT_DIR}/${workload}.txt"
    JOB_EXPECTED_FILE="${EXPECTED_DIR}/${workload}.json"

    JOB_TIMEOUT="$(workload_timeout "$workload")"

    JOB_TIMESTAMP="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

    JOB_ID="$(date +"%Y%m%d-%H%M%S")-${model//:/-}-${workload}"

}

############################################################

job_validate() {

    [[ -n "${JOB_PROVIDER}" ]] || return 1
    [[ -n "${JOB_PROFILE}" ]] || return 1
    [[ -n "${JOB_MODEL}" ]] || return 1
    [[ -n "${JOB_WORKLOAD}" ]] || return 1

    [[ -f "${JOB_PROMPT_FILE}" ]] || return 1

    return 0

}

############################################################

job_summary() {

cat <<EOF

Job ID      : ${JOB_ID}
Provider    : ${JOB_PROVIDER}
Profile     : ${JOB_PROFILE}
Model        : ${JOB_MODEL}
Workload     : ${JOB_WORKLOAD}
Iterations   : ${JOB_ITERATIONS}
Timeout      : ${JOB_TIMEOUT}s
Timestamp    : ${JOB_TIMESTAMP}

EOF

}

############################################################

job_has_expected_result() {

    [[ -f "${JOB_EXPECTED_FILE}" ]]

}