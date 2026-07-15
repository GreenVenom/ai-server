#!/usr/bin/env bash
set -u

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BENCHMARKS_DIR="$(cd "${TEST_DIR}/.." && pwd)"
source "${BENCHMARKS_DIR}/engines/benchmark-model.sh"

PASS_COUNT=0
FAIL_COUNT=0
pass(){ PASS_COUNT=$((PASS_COUNT+1)); printf "PASS: %s\n" "$1"; }
fail(){ FAIL_COUNT=$((FAIL_COUNT+1)); printf "FAIL: %s\n" "$1" >&2; }
assert_success(){ local d="$1"; shift; if "$@"; then pass "$d"; else fail "$d"; fi; }
assert_equals(){ local d="$1" e="$2" a="$3"; if [ "$e" = "$a" ]; then pass "$d"; else fail "$d (expected='$e', actual='$a')"; fi; }
assert_nonempty(){ local d="$1" v="$2"; if [ -n "$v" ]; then pass "$d"; else fail "$d"; fi; }

pass "benchmark-model.sh loads"
assert_success "Ollama provider is available" provider_available "$PROVIDER_OLLAMA"

benchmark_model_reset_config
assert_success "Standard profile applies" benchmark_model_apply_profile standard

MODEL_BENCHMARK_PROVIDER="$PROVIDER_OLLAMA"
MODEL_BENCHMARK_MODEL="$(model_preferred_generation "$PROVIDER_OLLAMA")"
MODEL_BENCHMARK_ITERATIONS=1
MODEL_BENCHMARK_WORKLOADS=()
benchmark_model_add_workload "$WORKLOAD_REASONING"

assert_nonempty "Generation model is selected" "$MODEL_BENCHMARK_MODEL"
assert_equals "Profile timeout is applied" "$PROFILE_TIMEOUT_SECONDS" "$MODEL_BENCHMARK_TIMEOUT_SECONDS"
assert_success "Engine configuration validates" benchmark_model_validate_config

if benchmark_model_run; then pass "Model benchmark run succeeds"; else fail "Model benchmark run succeeds"; fi

assert_equals "One result is created" 1 "$(results_count)"
assert_equals "Completed count is one" 1 "$(report_count_completed)"
assert_equals "Failed count is zero" 0 "$(report_count_failed)"
assert_nonempty "Engine report is generated" "$(benchmark_model_report)"

printf "\nPassed: %s\nFailed: %s\n" "$PASS_COUNT" "$FAIL_COUNT"
[ "$FAIL_COUNT" -eq 0 ]
