#!/usr/bin/env bash
set -u

BENCHMARK_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${BENCHMARK_SCRIPT_DIR}/engines/benchmark-model.sh"

usage() {
    cat <<EOF
Benchmark Framework

Usage:
  benchmark.sh [options]

Options:
  --provider NAME
  --model NAME
  --profile NAME
  --workload NAME       May be specified multiple times
  --iterations N        Overrides profile
  --timeout N           Overrides profile timeout
  --format FORMAT       text, json, markdown, csv
  --output FILE
  --list-models
  --list-workloads
  --list-profiles
  --help
EOF
}

benchmark_model_reset_config
CLI_PROFILE="$DEFAULT_PROFILE"
CLI_ITERATIONS=""
CLI_TIMEOUT=""
CLI_WORKLOADS=()

while [ "$#" -gt 0 ]; do
    case "$1" in
        --provider) MODEL_BENCHMARK_PROVIDER="$2"; shift 2 ;;
        --model) MODEL_BENCHMARK_MODEL="$2"; shift 2 ;;
        --profile) CLI_PROFILE="$2"; shift 2 ;;
        --workload) CLI_WORKLOADS[${#CLI_WORKLOADS[@]}]="$2"; shift 2 ;;
        --iterations) CLI_ITERATIONS="$2"; shift 2 ;;
        --timeout) CLI_TIMEOUT="$2"; shift 2 ;;
        --format) MODEL_BENCHMARK_OUTPUT_FORMAT="$2"; shift 2 ;;
        --output) MODEL_BENCHMARK_REPORT_FILE="$2"; shift 2 ;;
        --list-models) models_list "$MODEL_BENCHMARK_PROVIDER"; exit $? ;;
        --list-workloads) workloads_list; exit 0 ;;
        --list-profiles) profiles_list; exit 0 ;;
        --help|-h) usage; exit 0 ;;
        *) printf "Unknown argument: %s\n" "$1" >&2; usage >&2; exit "$EXIT_INVALID_ARGUMENT" ;;
    esac
done

benchmark_model_apply_profile "$CLI_PROFILE" || {
    printf "Failed to load benchmark profile '%s'.\n" "$CLI_PROFILE" >&2
    exit "$EXIT_INVALID_ARGUMENT"
}

[ -n "$CLI_ITERATIONS" ] && MODEL_BENCHMARK_ITERATIONS="$CLI_ITERATIONS"
[ -n "$CLI_TIMEOUT" ] && MODEL_BENCHMARK_TIMEOUT_SECONDS="$CLI_TIMEOUT"

if [ "${#CLI_WORKLOADS[@]}" -gt 0 ]; then
    MODEL_BENCHMARK_WORKLOADS=()
    for workload in "${CLI_WORKLOADS[@]}"; do
        benchmark_model_add_workload "$workload" || exit $?
    done
fi

if [ -z "$MODEL_BENCHMARK_MODEL" ]; then
    MODEL_BENCHMARK_MODEL="$(model_preferred_generation "$MODEL_BENCHMARK_PROVIDER")" || exit "$EXIT_MODEL_NOT_FOUND"
fi

if [ "${#MODEL_BENCHMARK_WORKLOADS[@]}" -eq 0 ]; then
    benchmark_model_default_workloads
fi

benchmark_model_validate_config || {
    printf "Invalid benchmark configuration.\n" >&2
    exit "$EXIT_INVALID_ARGUMENT"
}

printf "Benchmark Framework\n" >&2
printf "Provider   : %s\n" "$MODEL_BENCHMARK_PROVIDER" >&2
printf "Model      : %s\n" "$MODEL_BENCHMARK_MODEL" >&2
printf "Profile    : %s\n" "$MODEL_BENCHMARK_PROFILE" >&2
printf "Iterations : %s\n" "$MODEL_BENCHMARK_ITERATIONS" >&2
printf "Timeout    : %s seconds\n" "$MODEL_BENCHMARK_TIMEOUT_SECONDS" >&2
printf "Workloads  : %s\n\n" "${MODEL_BENCHMARK_WORKLOADS[*]}" >&2

benchmark_model_run
RUN_EXIT=$?

if [ -n "$MODEL_BENCHMARK_REPORT_FILE" ]; then
    REPORT_PARENT_DIR="$(dirname "$MODEL_BENCHMARK_REPORT_FILE")"

    if [ ! -d "$REPORT_PARENT_DIR" ]; then
        if ! mkdir -p "$REPORT_PARENT_DIR"; then
            printf "Failed to create report directory: %s\n" "$REPORT_PARENT_DIR" >&2
            exit "$EXIT_FAILURE"
        fi
    fi

    benchmark_model_save_report "$MODEL_BENCHMARK_REPORT_FILE"
    SAVE_EXIT=$?

    if [ "$SAVE_EXIT" -ne 0 ]; then
        printf "Failed to save benchmark report: %s\n" "$MODEL_BENCHMARK_REPORT_FILE" >&2
        exit "$SAVE_EXIT"
    fi

    printf "Report saved to: %s\n" "$MODEL_BENCHMARK_REPORT_FILE" >&2
else
    benchmark_model_report
fi

exit "$RUN_EXIT"
