#!/usr/bin/env bash
#
# ============================================================
# Personal AI Platform
# Benchmark Framework
#
# File: test-executor.sh
#
# Purpose:
#   Smoke-test executor integration across prompts, models,
#   providers, results, and errors.
#
# Usage:
#   ./benchmarks/tests/test-executor.sh
#
# Requirements:
#   - Ollama running
#   - At least one generation model installed
#   - nomic-embed-text installed for embedding validation
#
# Compatibility:
#   - Bash 3.2+
# ============================================================

set -u

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BENCHMARKS_DIR="$(cd "${TEST_DIR}/.." && pwd)"
CORE_DIR="${BENCHMARKS_DIR}/lib/core"

PASS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0

pass() {
    PASS_COUNT=$((PASS_COUNT + 1))
    printf "PASS: %s\n" "$1"
}

fail() {
    FAIL_COUNT=$((FAIL_COUNT + 1))
    printf "FAIL: %s\n" "$1" >&2
}

skip() {
    SKIP_COUNT=$((SKIP_COUNT + 1))
    printf "SKIP: %s\n" "$1"
}

assert_success() {
    local description="$1"
    shift

    if "$@"; then
        pass "$description"
    else
        fail "$description"
    fi
}

assert_failure() {
    local description="$1"
    shift

    if "$@"; then
        fail "$description"
    else
        pass "$description"
    fi
}

assert_equals() {
    local description="$1"
    local expected="$2"
    local actual="$3"

    if [ "$expected" = "$actual" ]; then
        pass "$description"
    else
        fail "$description (expected='${expected}', actual='${actual}')"
    fi
}

assert_nonempty() {
    local description="$1"
    local value="$2"

    if [ -n "$value" ]; then
        pass "$description"
    else
        fail "$description"
    fi
}

assert_integer_gt_zero() {
    local description="$1"
    local value="$2"

    if [ -n "$value" ] && [ "$value" -gt 0 ] 2>/dev/null; then
        pass "$description"
    else
        fail "$description (actual='${value}')"
    fi
}

printf "============================================================\n"
printf "Benchmark Framework Executor Smoke Test\n"
printf "============================================================\n\n"

if source "${CORE_DIR}/executor.sh"; then
    pass "executor.sh loads"
else
    fail "executor.sh loads"
    exit 1
fi

assert_success "Error repository resets" errors_reset
assert_success "Result repository resets" results_reset
assert_success "Ollama provider is available" provider_available "$PROVIDER_OLLAMA"

# ------------------------------------------------------------
# Generation execution
# ------------------------------------------------------------

GENERATION_MODEL="$(model_preferred_generation "$PROVIDER_OLLAMA" 2>/dev/null || true)"
assert_nonempty "Preferred generation model is available" "$GENERATION_MODEL"

if [ -n "$GENERATION_MODEL" ]; then
    executor_execute_prompt \
        "$PROVIDER_OLLAMA" \
        "$GENERATION_MODEL" \
        "$DEFAULT_PROFILE" \
        "$WORKLOAD_REASONING" \
        "Reply with exactly the word READY." \
        "60" >/dev/null

    GENERATION_EXIT=$?
    GENERATION_RESULT_ID="$RESULT_LAST_ID"

    if [ "$GENERATION_EXIT" -eq 0 ]; then
        pass "Generation executor call succeeds"
    else
        fail "Generation executor call succeeds"
    fi

    assert_nonempty "Generation result ID is recorded" "$GENERATION_RESULT_ID"
    assert_success "Generation result exists" result_exists "$GENERATION_RESULT_ID"

    assert_equals \
        "Generation result status is completed" \
        "$RESULT_STATUS_COMPLETED" \
        "$(result_status_get "$GENERATION_RESULT_ID")"

    assert_equals \
        "Generation result provider is stored" \
        "$PROVIDER_OLLAMA" \
        "$(result_provider_get "$GENERATION_RESULT_ID")"

    assert_equals \
        "Generation result model is stored" \
        "$GENERATION_MODEL" \
        "$(result_model_get "$GENERATION_RESULT_ID")"

    assert_equals \
        "Generation result workload is stored" \
        "$WORKLOAD_REASONING" \
        "$(result_workload_get "$GENERATION_RESULT_ID")"

    assert_nonempty \
        "Generation output is captured" \
        "$(result_output_get "$GENERATION_RESULT_ID")"

    assert_integer_gt_zero \
        "Generation duration milliseconds are recorded" \
        "$(result_duration_ms_get "$GENERATION_RESULT_ID")"

    assert_nonempty \
        "Generation duration seconds are recorded" \
        "$(result_duration_seconds_get "$GENERATION_RESULT_ID")"

    assert_integer_gt_zero \
        "Generation token count is recorded" \
        "$(result_tokens_get "$GENERATION_RESULT_ID")"

    assert_nonempty \
        "Generation throughput is recorded" \
        "$(result_tokens_per_second_get "$GENERATION_RESULT_ID")"

    assert_equals \
        "Generation exit code is zero" \
        "0" \
        "$(result_exit_code_get "$GENERATION_RESULT_ID")"

    assert_success \
        "Generation result validates" \
        result_validate "$GENERATION_RESULT_ID"
fi

# ------------------------------------------------------------
# Prompt-file workload execution
# ------------------------------------------------------------

if [ -n "$GENERATION_MODEL" ]; then
    executor_execute_workload \
        "$PROVIDER_OLLAMA" \
        "$GENERATION_MODEL" \
        "quick" \
        "$WORKLOAD_REASONING" \
        "60" >/dev/null

    WORKLOAD_EXIT=$?
    WORKLOAD_RESULT_ID="$RESULT_LAST_ID"

    if [ "$WORKLOAD_EXIT" -eq 0 ]; then
        pass "Prompt-file workload execution succeeds"
    else
        fail "Prompt-file workload execution succeeds"
    fi

    assert_nonempty "Workload result ID is recorded" "$WORKLOAD_RESULT_ID"

    assert_equals \
        "Workload result profile is stored" \
        "quick" \
        "$(result_profile_get "$WORKLOAD_RESULT_ID")"

    assert_nonempty \
        "Workload prompt is stored" \
        "$(result_prompt_get "$WORKLOAD_RESULT_ID")"

    assert_equals \
        "Workload result status is completed" \
        "$RESULT_STATUS_COMPLETED" \
        "$(result_status_get "$WORKLOAD_RESULT_ID")"
fi

# ------------------------------------------------------------
# Embedding execution
# ------------------------------------------------------------

EMBEDDING_MODEL="$(model_preferred_embedding "$PROVIDER_OLLAMA" 2>/dev/null || true)"

if [ -n "$EMBEDDING_MODEL" ]; then
    pass "Preferred embedding model is available"

    executor_execute_prompt \
        "$PROVIDER_OLLAMA" \
        "$EMBEDDING_MODEL" \
        "$DEFAULT_PROFILE" \
        "$WORKLOAD_EMBEDDING" \
        "Benchmark executor embedding smoke test." \
        "60" >/dev/null

    EMBEDDING_EXIT=$?
    EMBEDDING_RESULT_ID="$RESULT_LAST_ID"

    if [ "$EMBEDDING_EXIT" -eq 0 ]; then
        pass "Embedding executor call succeeds"
    else
        fail "Embedding executor call succeeds"
    fi

    assert_nonempty "Embedding result ID is recorded" "$EMBEDDING_RESULT_ID"
    assert_success "Embedding result exists" result_exists "$EMBEDDING_RESULT_ID"

    assert_equals \
        "Embedding result status is completed" \
        "$RESULT_STATUS_COMPLETED" \
        "$(result_status_get "$EMBEDDING_RESULT_ID")"

    assert_equals \
        "Embedding workload is stored" \
        "$WORKLOAD_EMBEDDING" \
        "$(result_workload_get "$EMBEDDING_RESULT_ID")"

    assert_nonempty \
        "Embedding response is captured" \
        "$(result_output_get "$EMBEDDING_RESULT_ID")"

    assert_integer_gt_zero \
        "Embedding vector dimension is recorded" \
        "$(result_tokens_get "$EMBEDDING_RESULT_ID")"

    assert_success \
        "Embedding result validates" \
        result_validate "$EMBEDDING_RESULT_ID"
else
    skip "Embedding execution because no embedding model is available"
fi

# ------------------------------------------------------------
# Failure handling
# ------------------------------------------------------------

RESULTS_BEFORE="$(results_count)"

if executor_execute_prompt \
    "$PROVIDER_OLLAMA" \
    "definitely-not-installed:model" \
    "$DEFAULT_PROFILE" \
    "$WORKLOAD_REASONING" \
    "test" \
    "10" >/dev/null 2>&1
then
    fail "Missing model execution is rejected"
else
    pass "Missing model execution is rejected"
fi

RESULTS_AFTER="$(results_count)"

if [ "$RESULTS_AFTER" -gt "$RESULTS_BEFORE" ]; then
    pass "Failed execution still creates a Result object"
else
    fail "Failed execution still creates a Result object"
fi

FAILED_RESULT_ID="$RESULT_LAST_ID"
assert_nonempty "Failed execution has a Result ID" "$FAILED_RESULT_ID"

if [ -n "$FAILED_RESULT_ID" ]; then
    assert_equals \
        "Failed execution result status is failed" \
        "$RESULT_STATUS_FAILED" \
        "$(result_status_get "$FAILED_RESULT_ID")"

    assert_nonempty \
        "Failed execution records an error message" \
        "$(result_error_get "$FAILED_RESULT_ID")"

    assert_nonempty \
        "Failed execution records an exit code" \
        "$(result_exit_code_get "$FAILED_RESULT_ID")"
fi

# ------------------------------------------------------------
# Invalid argument handling
# ------------------------------------------------------------

RESULTS_BEFORE="$(results_count)"

assert_failure \
    "Invalid workload is rejected before execution" \
    executor_execute_prompt \
        "$PROVIDER_OLLAMA" \
        "$GENERATION_MODEL" \
        "$DEFAULT_PROFILE" \
        "not-a-workload" \
        "test" \
        "10"

RESULTS_AFTER="$(results_count)"

assert_equals \
    "Invalid workload does not create a Result object" \
    "$RESULTS_BEFORE" \
    "$RESULTS_AFTER"

# ------------------------------------------------------------
# Repository validation
# ------------------------------------------------------------

assert_success "Result repository validates after execution tests" results_validate

# ------------------------------------------------------------
# Summary
# ------------------------------------------------------------

printf "\n============================================================\n"
printf "Smoke Test Summary\n"
printf "============================================================\n"
printf "Passed:  %s\n" "$PASS_COUNT"
printf "Failed:  %s\n" "$FAIL_COUNT"
printf "Skipped: %s\n" "$SKIP_COUNT"

if [ "$FAIL_COUNT" -gt 0 ]; then
    printf "\nResult: FAILED\n" >&2
    exit 1
fi

printf "\nResult: PASSED\n"
exit 0
