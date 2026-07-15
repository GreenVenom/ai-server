#!/usr/bin/env bash
[[ -n "${BENCHMARK_MODEL_ENGINE_LOADED:-}" ]] && return 0
BENCHMARK_MODEL_ENGINE_LOADED=1

ENGINE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BENCHMARKS_DIR="$(cd "${ENGINE_DIR}/.." && pwd)"
LIB_DIR="${BENCHMARKS_DIR}/lib"
API_DIR="${LIB_DIR}/api"
CORE_DIR="${LIB_DIR}/core"

source "${CORE_DIR}/executor.sh"
source "${CORE_DIR}/profile.sh"
source "${API_DIR}/reporting.sh"

MODEL_BENCHMARK_PROVIDER="$DEFAULT_PROVIDER"
MODEL_BENCHMARK_MODEL=""
MODEL_BENCHMARK_PROFILE="$DEFAULT_PROFILE"
MODEL_BENCHMARK_ITERATIONS="$DEFAULT_ITERATIONS"
MODEL_BENCHMARK_TIMEOUT_SECONDS="$DEFAULT_TIMEOUT_SECONDS"
MODEL_BENCHMARK_OUTPUT_FORMAT="$OUTPUT_FORMAT_TEXT"
MODEL_BENCHMARK_REPORT_FILE=""
MODEL_BENCHMARK_WORKLOADS=()

benchmark_model_reset_config() {
    MODEL_BENCHMARK_PROVIDER="$DEFAULT_PROVIDER"
    MODEL_BENCHMARK_MODEL=""
    MODEL_BENCHMARK_PROFILE="$DEFAULT_PROFILE"
    MODEL_BENCHMARK_ITERATIONS="$DEFAULT_ITERATIONS"
    MODEL_BENCHMARK_TIMEOUT_SECONDS="$DEFAULT_TIMEOUT_SECONDS"
    MODEL_BENCHMARK_OUTPUT_FORMAT="$OUTPUT_FORMAT_TEXT"
    MODEL_BENCHMARK_REPORT_FILE=""
    MODEL_BENCHMARK_WORKLOADS=()
}

benchmark_model_add_workload() {
    local workload="$1"
    workload_valid "$workload" || return "$EXIT_WORKLOAD_NOT_FOUND"
    MODEL_BENCHMARK_WORKLOADS[${#MODEL_BENCHMARK_WORKLOADS[@]}]="$workload"
}

benchmark_model_default_workloads() {
    MODEL_BENCHMARK_WORKLOADS=(
        "$WORKLOAD_REASONING"
        "$WORKLOAD_CODING"
        "$WORKLOAD_SUMMARIZATION"
        "$WORKLOAD_EXTRACTION"
        "$WORKLOAD_CLASSIFICATION"
    )
}

benchmark_model_apply_profile() {
    local name="$1"
    profile_load "$name" || return $?

    MODEL_BENCHMARK_PROFILE="$PROFILE_NAME"
    MODEL_BENCHMARK_ITERATIONS="$PROFILE_ITERATIONS"
    MODEL_BENCHMARK_TIMEOUT_SECONDS="$PROFILE_TIMEOUT_SECONDS"

    if [ "${#PROFILE_WORKLOADS[@]}" -gt 0 ]; then
        MODEL_BENCHMARK_WORKLOADS=()
        local workload
        for workload in "${PROFILE_WORKLOADS[@]}"; do
            MODEL_BENCHMARK_WORKLOADS[${#MODEL_BENCHMARK_WORKLOADS[@]}]="$workload"
        done
    fi
}

benchmark_model_validate_config() {
    provider_valid "$MODEL_BENCHMARK_PROVIDER" || return "$EXIT_INVALID_ARGUMENT"
    [ -n "$MODEL_BENCHMARK_MODEL" ] || return "$EXIT_INVALID_ARGUMENT"
    model_exists "$MODEL_BENCHMARK_PROVIDER" "$MODEL_BENCHMARK_MODEL" || return "$EXIT_MODEL_NOT_FOUND"
    is_integer "$MODEL_BENCHMARK_ITERATIONS" || return "$EXIT_INVALID_ARGUMENT"
    [ "$MODEL_BENCHMARK_ITERATIONS" -gt 0 ] || return "$EXIT_INVALID_ARGUMENT"
    is_integer "$MODEL_BENCHMARK_TIMEOUT_SECONDS" || return "$EXIT_INVALID_ARGUMENT"
    [ "$MODEL_BENCHMARK_TIMEOUT_SECONDS" -gt 0 ] || return "$EXIT_INVALID_ARGUMENT"
    output_format_valid "$MODEL_BENCHMARK_OUTPUT_FORMAT" || return "$EXIT_INVALID_ARGUMENT"
    [ "${#MODEL_BENCHMARK_WORKLOADS[@]}" -gt 0 ] || return "$EXIT_INVALID_ARGUMENT"

    local workload
    for workload in "${MODEL_BENCHMARK_WORKLOADS[@]}"; do
        workload_valid "$workload" || return "$EXIT_WORKLOAD_NOT_FOUND"
        prompt_validate "$workload" || return "$EXIT_WORKLOAD_NOT_FOUND"
    done
}

benchmark_model_run() {
    benchmark_model_validate_config || return $?
    results_reset || return "$EXIT_FAILURE"

    local workload iteration failed=0
    for workload in "${MODEL_BENCHMARK_WORKLOADS[@]}"; do
        iteration=1
        while [ "$iteration" -le "$MODEL_BENCHMARK_ITERATIONS" ]; do
            if ! executor_execute_workload                 "$MODEL_BENCHMARK_PROVIDER"                 "$MODEL_BENCHMARK_MODEL"                 "$MODEL_BENCHMARK_PROFILE"                 "$workload"                 "$MODEL_BENCHMARK_TIMEOUT_SECONDS" >/dev/null
            then
                failed=$((failed + 1))
            fi
            iteration=$((iteration + 1))
        done
    done

    [ "$failed" -eq 0 ]
}

benchmark_model_report() {
    case "$MODEL_BENCHMARK_OUTPUT_FORMAT" in
        "$OUTPUT_FORMAT_TEXT") report_summary_text ;;
        "$OUTPUT_FORMAT_JSON") report_summary_json ;;
        "$OUTPUT_FORMAT_MARKDOWN") report_summary_markdown ;;
        "$OUTPUT_FORMAT_CSV") report_summary_csv ;;
        *) return "$EXIT_INVALID_ARGUMENT" ;;
    esac
}

benchmark_model_save_report() {
    local file="$1"
    [ -n "$file" ] || return "$EXIT_INVALID_ARGUMENT"
    case "$MODEL_BENCHMARK_OUTPUT_FORMAT" in
        "$OUTPUT_FORMAT_TEXT") report_save_text "$file" ;;
        "$OUTPUT_FORMAT_JSON") report_save_json "$file" ;;
        "$OUTPUT_FORMAT_MARKDOWN") report_save_markdown "$file" ;;
        "$OUTPUT_FORMAT_CSV") report_save_csv "$file" ;;
        *) return "$EXIT_INVALID_ARGUMENT" ;;
    esac
}
