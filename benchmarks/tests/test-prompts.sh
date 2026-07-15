#!/usr/bin/env bash
#
# ============================================================
# Personal AI Platform
# Benchmark Framework
#
# File: test-prompts.sh
#
# Purpose:
#   Smoke-test prompt and workload access.
#
# Usage:
#   ./benchmarks/tests/test-prompts.sh
#
# Compatibility:
#   - Bash 3.2+
# ============================================================

set -u

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BENCHMARKS_DIR="$(cd "${TEST_DIR}/.." && pwd)"
API_DIR="${BENCHMARKS_DIR}/lib/api"

PASS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0

pass() { PASS_COUNT=$((PASS_COUNT + 1)); printf "PASS: %s\n" "$1"; }
fail() { FAIL_COUNT=$((FAIL_COUNT + 1)); printf "FAIL: %s\n" "$1" >&2; }
skip() { SKIP_COUNT=$((SKIP_COUNT + 1)); printf "SKIP: %s\n" "$1"; }

assert_success() {
    local description="$1"
    shift
    if "$@"; then pass "$description"; else fail "$description"; fi
}

assert_failure() {
    local description="$1"
    shift
    if "$@"; then fail "$description"; else pass "$description"; fi
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

    if [ -n "$value" ]; then pass "$description"; else fail "$description"; fi
}

printf "============================================================\n"
printf "Benchmark Framework Prompt API Smoke Test\n"
printf "============================================================\n\n"

if source "${API_DIR}/prompts.sh"; then
    pass "prompts.sh loads"
else
    fail "prompts.sh loads"
    exit 1
fi

assert_success "Reasoning workload is valid" workload_valid "$WORKLOAD_REASONING"
assert_failure "Unknown workload is rejected" workload_valid "not-a-workload"

WORKLOAD_LIST="$(workloads_list)"
assert_nonempty "Workload list is returned" "$WORKLOAD_LIST"

for workload in \
    "$WORKLOAD_REASONING" \
    "$WORKLOAD_CODING" \
    "$WORKLOAD_SUMMARIZATION" \
    "$WORKLOAD_EXTRACTION" \
    "$WORKLOAD_CLASSIFICATION" \
    "$WORKLOAD_CREATIVE"
do
    assert_success "${workload} prompt exists" prompt_exists "$workload"
    assert_success "${workload} prompt validates" prompt_validate "$workload"

    PROMPT_TEXT="$(prompt_load "$workload")"
    assert_nonempty "${workload} prompt loads" "$PROMPT_TEXT"

    PROMPT_PATH="$(prompt_file "$workload")"
    assert_nonempty "${workload} prompt path resolves" "$PROMPT_PATH"

    DESCRIPTION="$(workload_description "$workload")"
    assert_nonempty "${workload} description resolves" "$DESCRIPTION"

    TIMEOUT="$(workload_timeout "$workload")"
    assert_nonempty "${workload} timeout resolves" "$TIMEOUT"
done

assert_success "All required prompts validate" prompts_validate_all

MISSING_PROMPTS="$(workloads_missing_prompts)"

if [ -z "$MISSING_PROMPTS" ] || [ "$MISSING_PROMPTS" = "$WORKLOAD_EMBEDDING" ]; then
    pass "No unexpected prompt files are missing"
else
    fail "No unexpected prompt files are missing"
fi

for workload in "${WORKLOAD_ENUM[@]}"; do
    if expected_exists "$workload"; then
        EXPECTED_TEXT="$(expected_load "$workload")"
        assert_nonempty "${workload} expected output loads" "$EXPECTED_TEXT"
    else
        skip "${workload} expected output file not present"
    fi
done

assert_failure "Unknown workload prompt does not exist" prompt_exists "not-a-workload"
assert_failure "Unknown workload prompt cannot be loaded" prompt_load "not-a-workload"

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
