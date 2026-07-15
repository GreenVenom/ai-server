#!/usr/bin/env bash
#
# ============================================================
# Personal AI Platform
# Benchmark Framework
#
# File: benchmark.sh
#
# Purpose:
#   Root command-line entry point for the Benchmark Framework.
#
# Usage:
#   ./benchmarks/benchmark.sh [options]
#
# Examples:
#   ./benchmarks/benchmark.sh
#   ./benchmarks/benchmark.sh --model qwen3:14b
#   ./benchmarks/benchmark.sh --model gemma4:12b --workload reasoning
#   ./benchmarks/benchmark.sh --iterations 3 --format markdown
#   ./benchmarks/benchmark.sh --output benchmarks/reports/latest.md
#
# Compatibility:
#   - Bash 3.2+
# ============================================================

set -u

BENCHMARK_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENGINE_DIR="${BENCHMARK_SCRIPT_DIR}/engines"

# shellcheck source=/dev/null
source "${ENGINE_DIR}/benchmark-model.sh"

usage() {
    cat <<EOF
Benchmark Framework

Usage:
  benchmark.sh [options]

Options:
  --provider NAME       Provider name (default: ${DEFAULT_PROVIDER})
  --model NAME          Model name (default: preferred generation model)
  --profile NAME        Profile label (default: ${DEFAULT_PROFILE})
  --workload NAME       Add workload; may be specified multiple times
  --iterations N        Iterations per workload (default: ${DEFAULT_ITERATIONS})
  --format FORMAT       text, json, markdown, or csv
  --output FILE         Save report to file instead of stdout
  --list-models         List provider models and exit
  --list-workloads      List supported workloads and exit
  --help                Show this help
EOF
}

benchmark_model_reset_config

while [ "$#" -gt 0 ]; do
    case "$1" in
        --provider)
            [ "$#" -ge 2 ] || { printf "Missing value for --provider\n" >&2; exit "$EXIT_INVALID_ARGUMENT"; }
            MODEL_BENCHMARK_PROVIDER="$2"
            shift 2
            ;;
        --model)
            [ "$#" -ge 2 ] || { printf "Missing value for --model\n" >&2; exit "$EXIT_INVALID_ARGUMENT"; }
            MODEL_BENCHMARK_MODEL="$2"
            shift 2
            ;;
        --profile)
            [ "$#" -ge 2 ] || { printf "Missing value for --profile\n" >&2; exit "$EXIT_INVALID_ARGUMENT"; }
            MODEL_BENCHMARK_PROFILE="$2"
            shift 2
            ;;
        --workload)
            [ "$#" -ge 2 ] || { printf "Missing value for --workload\n" >&2; exit "$EXIT_INVALID_ARGUMENT"; }
            benchmark_model_add_workload "$2" || exit $?
            shift 2
            ;;
        --iterations)
            [ "$#" -ge 2 ] || { printf "Missing value for --iterations\n" >&2; exit "$EXIT_INVALID_ARGUMENT"; }
            MODEL_BENCHMARK_ITERATIONS="$2"
            shift 2
            ;;
        --format)
            [ "$#" -ge 2 ] || { printf "Missing value for --format\n" >&2; exit "$EXIT_INVALID_ARGUMENT"; }
            MODEL_BENCHMARK_OUTPUT_FORMAT="$2"
            shift 2
            ;;
        --output)
            [ "$#" -ge 2 ] || { printf "Missing value for --output\n" >&2; exit "$EXIT_INVALID_ARGUMENT"; }
            MODEL_BENCHMARK_REPORT_FILE="$2"
            shift 2
            ;;
        --list-models)
            models_list "$MODEL_BENCHMARK_PROVIDER"
            exit $?
            ;;
        --list-workloads)
            workloads_list
            exit 0
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            printf "Unknown argument: %s\n\n" "$1" >&2
            usage >&2
            exit "$EXIT_INVALID_ARGUMENT"
            ;;
    esac
done

if [ -z "$MODEL_BENCHMARK_MODEL" ]; then
    MODEL_BENCHMARK_MODEL="$(model_preferred_generation "$MODEL_BENCHMARK_PROVIDER")" || {
        printf "No generation model available for provider '%s'.\n" "$MODEL_BENCHMARK_PROVIDER" >&2
        exit "$EXIT_MODEL_NOT_FOUND"
    }
fi

if [ "${#MODEL_BENCHMARK_WORKLOADS[@]}" -eq 0 ]; then
    benchmark_model_default_workloads
fi

if ! benchmark_model_validate_config; then
    printf "Invalid benchmark configuration.\n" >&2
    exit "$EXIT_INVALID_ARGUMENT"
fi

printf "Benchmark Framework\n" >&2
printf "Provider   : %s\n" "$MODEL_BENCHMARK_PROVIDER" >&2
printf "Model      : %s\n" "$MODEL_BENCHMARK_MODEL" >&2
printf "Profile    : %s\n" "$MODEL_BENCHMARK_PROFILE" >&2
printf "Iterations : %s\n" "$MODEL_BENCHMARK_ITERATIONS" >&2
printf "Workloads  : %s\n" "${MODEL_BENCHMARK_WORKLOADS[*]}" >&2
printf "\n" >&2

benchmark_model_run
RUN_EXIT=$?

if [ -n "$MODEL_BENCHMARK_REPORT_FILE" ]; then
    benchmark_model_save_report "$MODEL_BENCHMARK_REPORT_FILE" || exit $?
    printf "Report saved to: %s\n" "$MODEL_BENCHMARK_REPORT_FILE" >&2
else
    benchmark_model_report
fi

exit "$RUN_EXIT"
