#!/usr/bin/env bash
#
# ============================================================
# Personal AI Platform
# Benchmark Framework
#
# File: benchmark-model.sh
#
# Purpose:
#   Engine for benchmarking one model across one or more
#   workloads and iterations.
#
# Responsibilities:
#   - Model benchmark orchestration
#   - Iteration control
#   - Workload selection
#   - Result repository population
#   - Report generation
#
# Compatibility:
#   - Bash 3.2+
# ============================================================

[[ -n "${BENCHMARK_MODEL_ENGINE_LOADED:-}" ]] && return 0
BENCHMARK_MODEL_ENGINE_LOADED=1

ENGINE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BENCHMARKS_DIR="$(cd "${ENGINE_DIR}/.." && pwd)"
LIB_DIR="${BENCHMARKS_DIR}/lib"
API_DIR="${LIB_DIR}/api"
CORE_DIR="${LIB_DIR}/core"

# shellcheck source=/dev/null
source "${CORE_DIR}/executor.sh"

# shellcheck source=/dev/null
source "${API_DIR}/reporting.sh"

# ------------------------------------------------------------
# Defaults
# ------------------------------------------------------------

MODEL_BENCHMARK_PROVIDER="$DEFAULT_PROVIDER"
MODEL_BENCHMARK_MODEL=""
MODEL_BENCHMARK_PROFILE="$DEFAULT_PROFILE"
MODEL_BENCHMARK_ITERATIONS="$DEFAULT_ITERATIONS"
MODEL_BENCHMARK_OUTPUT_FORMAT="$OUTPUT_FORMAT_TEXT"
MODEL_BENCHMARK_REPORT_FILE=""

MODEL_BENCHMARK_WORKLOADS=()

# ------------------------------------------------------------
# Configuration helpers
# ------------------------------------------------------------

benchmark_model_reset_config() {
    MODEL_BENCHMARK_PROVIDER="$DEFAULT_PROVIDER"
    MODEL_BENCHMARK_MODEL=""
    MODEL_BENCHMARK_PROFILE="$DEFAULT_PROFILE"
    MODEL_BENCHMARK_ITERATIONS="$DEFAULT_ITERATIONS"
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

benchmark_model_validate_config() {
    provider_valid "$MODEL_BENCHMARK_PROVIDER" || return "$EXIT_INVALID_ARGUMENT"
    [ -n "$MODEL_BENCHMARK_MODEL" ] || return "$EXIT_INVALID_ARGUMENT"
    model_exists "$MODEL_BENCHMARK_PROVIDER" "$MODEL_BENCHMARK_MODEL" || return "$EXIT_MODEL_NOT_FOUND"
    is_integer "$MODEL_BENCHMARK_ITERATIONS" || return "$EXIT_INVALID_ARGUMENT"
    [ "$MODEL_BENCHMARK_ITERATIONS" -gt 0 ] || return "$EXIT_INVALID_ARGUMENT"
    output_format_valid "$MODEL_BENCHMARK_OUTPUT_FORMAT" || return "$EXIT_INVALID_ARGUMENT"
    [ "${#MODEL_BENCHMARK_WORKLOADS[@]}" -gt 0 ] || return "$EXIT_INVALID_ARGUMENT"

    local workload
    for workload in "${MODEL_BENCHMARK_WORKLOADS[@]}"; do
        workload_valid "$workload" || return "$EXIT_WORKLOAD_NOT_FOUND"
        prompt_validate "$workload" || return "$EXIT_WORKLOAD_NOT_FOUND"
    done

    return "$EXIT_SUCCESS"
}

# ------------------------------------------------------------
# Execution
# ------------------------------------------------------------

benchmark_model_run() {
    benchmark_model_validate_config || return $?

    results_reset || return "$EXIT_FAILURE"

    local workload
    local iteration
    local failed=0

    for workload in "${MODEL_BENCHMARK_WORKLOADS[@]}"; do
        iteration=1

        while [ "$iteration" -le "$MODEL_BENCHMARK_ITERATIONS" ]; do
            if ! executor_execute_workload \
                "$MODEL_BENCHMARK_PROVIDER" \
                "$MODEL_BENCHMARK_MODEL" \
                "$MODEL_BENCHMARK_PROFILE" \
                "$workload" >/dev/null
            then
                failed=$((failed + 1))
            fi

            iteration=$((iteration + 1))
        done
    done

    if [ "$failed" -gt 0 ]; then
        return "$EXIT_EXECUTION_FAILED"
    fi

    return "$EXIT_SUCCESS"
}

# ------------------------------------------------------------
# Reporting
# ------------------------------------------------------------

benchmark_model_report() {
    case "$MODEL_BENCHMARK_OUTPUT_FORMAT" in
        "$OUTPUT_FORMAT_TEXT")
            report_summary_text
            ;;
        "$OUTPUT_FORMAT_JSON")
            report_summary_json
            ;;
        "$OUTPUT_FORMAT_MARKDOWN")
            report_summary_markdown
            ;;
        "$OUTPUT_FORMAT_CSV")
            report_summary_csv
            ;;
        *)
            return "$EXIT_INVALID_ARGUMENT"
            ;;
    esac
}

benchmark_model_save_report() {
    local file="$1"

    [ -n "$file" ] || return "$EXIT_INVALID_ARGUMENT"

    case "$MODEL_BENCHMARK_OUTPUT_FORMAT" in
        "$OUTPUT_FORMAT_TEXT")
            report_save_text "$file"
            ;;
        "$OUTPUT_FORMAT_JSON")
            report_save_json "$file"
            ;;
        "$OUTPUT_FORMAT_MARKDOWN")
            report_save_markdown "$file"
            ;;
        "$OUTPUT_FORMAT_CSV")
            report_save_csv "$file"
            ;;
        *)
            return "$EXIT_INVALID_ARGUMENT"
            ;;
    esac
}
