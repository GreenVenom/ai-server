#!/usr/bin/env bash
#
# ============================================================
# Personal AI Platform
# Benchmark Framework
#
# File: test-benchmark-model.sh
#
# Purpose:
#   Smoke-test the model benchmark engine.
#
# Usage:
#   ./benchmarks/tests/test-benchmark-model.sh
#
# Compatibility:
#   - Bash 3.2+
# ============================================================

set -u

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BENCHMARKS_DIR="$(cd "${TEST_DIR}/.." && pwd)"
ENGINE_DIR="${BENCHMARKS_DIR}/engines"

PASS_COUNT=0
FAIL_COUNT=0

pass() { PASS_COUNT=$((PASS_COUNT + 1)); printf "PASS: %s\n" "$1"; }
fail() { FAIL_COUNT=$((FAIL_COUNT + 1)); printf "FAIL: %s\n" "$1" >&2; }

assert_success() {
    local d="$1"
    shift
    if "$@"; then pass "$d"; else fail "$d"; fi
}

assert_equals() {
    local d="$1"
    local e="$2"
    local a="$3"

    if [ "$e" = "$a" ]; then
        pass "$d"
    else
        fail "$d (expected='${e}', actual='${a}')"
    fi
}

assert_nonempty() {
    local d="$1"
    local v="$2"

    if [ -n "$v" ]; then pass "$d"; else fail "$d"; fi
}

printf "============================================================\n"
printf "Benchmark Model Engine Smoke Test\n"
printf "============================================================\n\n"

if source "${ENGINE_DIR}/benchmark-model.sh"; then
    pass "benchmark-model.sh loads"
else
    fail "benchmark-model.sh loads"
    exit 1
fi

assert_success "Ollama provider is available" provider_available "$PROVIDER_OLLAMA"

benchmark_model_reset_config

MODEL_BENCHMARK_PROVIDER="$PROVIDER_OLLAMA"
MODEL_BENCHMARK_MODEL="$(model_preferred_generation "$PROVIDER_OLLAMA")"
MODEL_BENCHMARK_PROFILE="quick"
MODEL_BENCHMARK_ITERATIONS=1
MODEL_BENCHMARK_OUTPUT_FORMAT="$OUTPUT_FORMAT_TEXT"

MODEL_BENCHMARK_WORKLOADS=()
benchmark_model_add_workload "$WORKLOAD_REASONING"

assert_nonempty "Generation model is selected" "$MODEL_BENCHMARK_MODEL"
assert_success "Engine configuration validates" benchmark_model_validate_config

if benchmark_model_run; then
    pass "Model benchmark run succeeds"
else
    fail "Model benchmark run succeeds"
fi

assert_equals "One result is created" "1" "$(results_count)"
assert_equals "Completed count is one" "1" "$(report_count_completed)"
assert_equals "Failed count is zero" "0" "$(report_count_failed)"

REPORT_TEXT="$(benchmark_model_report)"
assert_nonempty "Engine report is generated" "$REPORT_TEXT"

RESULT_ID="$RESULT_LAST_ID"
assert_nonempty "Result ID exists after benchmark" "$RESULT_ID"
assert_equals \
    "Result model matches selected model" \
    "$MODEL_BENCHMARK_MODEL" \
    "$(result_model_get "$RESULT_ID")"

printf "\n============================================================\n"
printf "Smoke Test Summary\n"
printf "============================================================\n"
printf "Passed: %s\n" "$PASS_COUNT"
printf "Failed: %s\n" "$FAIL_COUNT"

if [ "$FAIL_COUNT" -gt 0 ]; then
    printf "\nResult: FAILED\n" >&2
    exit 1
fi

printf "\nResult: PASSED\n"
exit 0
