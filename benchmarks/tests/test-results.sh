#!/usr/bin/env bash
#
# Benchmark Framework Result Repository Smoke Test
# Bash 3.2 compatible.
#

set -u

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BENCHMARKS_DIR="$(cd "${TEST_DIR}/.." && pwd)"
API_DIR="${BENCHMARKS_DIR}/lib/api"

PASS_COUNT=0
FAIL_COUNT=0

pass() { PASS_COUNT=$((PASS_COUNT + 1)); printf "PASS: %s\n" "$1"; }
fail() { FAIL_COUNT=$((FAIL_COUNT + 1)); printf "FAIL: %s\n" "$1" >&2; }

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

assert_file_nonempty() {
    local description="$1"
    local file="$2"

    if [ -s "$file" ]; then pass "$description"; else fail "$description"; fi
}

cleanup() {
    rm -f \
        "${TEST_DIR}/.test-results.json" \
        "${TEST_DIR}/.test-results.csv" \
        "${TEST_DIR}/.test-results.md" \
        "${TEST_DIR}/.test-results.txt"
}
trap cleanup EXIT

printf "============================================================\n"
printf "Benchmark Framework Result Repository Smoke Test\n"
printf "============================================================\n\n"

source "${API_DIR}/errors.sh"
pass "errors.sh loads"

source "${API_DIR}/results.sh"
pass "results.sh loads"

assert_success "Error repository resets" errors_reset
assert_success "Result repository resets" results_reset
assert_equals "Initial error count is zero" "0" "$(errors_count)"
assert_equals "Initial result count is zero" "0" "$(results_count)"

# IMPORTANT:
# Mutating repository functions MUST execute in the current shell.
# Do not wrap result_create/result_set/result_delete in $(...).

result_create \
    "$DEFAULT_PROVIDER" \
    "smoke-test-model" \
    "$DEFAULT_PROFILE" \
    "$WORKLOAD_REASONING" \
    "Explain why deterministic tests are useful." >/dev/null

RESULT_ID="$RESULT_LAST_ID"

assert_nonempty "Valid result returns an ID" "$RESULT_ID"
assert_success "Created result exists" result_exists "$RESULT_ID"
assert_equals "Result count increments" "1" "$(results_count)"
assert_equals "Last result matches created result" "$RESULT_ID" "$(result_last)"

assert_equals "Provider is stored" "$DEFAULT_PROVIDER" "$(result_provider_get "$RESULT_ID")"
assert_equals "Model is stored" "smoke-test-model" "$(result_model_get "$RESULT_ID")"
assert_equals "Profile is stored" "$DEFAULT_PROFILE" "$(result_profile_get "$RESULT_ID")"
assert_equals "Workload is stored" "$WORKLOAD_REASONING" "$(result_workload_get "$RESULT_ID")"
assert_equals "Initial status is created" "$DEFAULT_RESULT_STATUS" "$(result_status_get "$RESULT_ID")"

assert_success "Duration milliseconds can be set" result_duration_ms_set "$RESULT_ID" "1250"
assert_success "Duration seconds can be set" result_duration_seconds_set "$RESULT_ID" "1.25"
assert_success "Token count can be set" result_tokens_set "$RESULT_ID" "250"
assert_success "Tokens per second can be set" result_tokens_per_second_set "$RESULT_ID" "200.0"
assert_success "Memory can be set" result_memory_mb_set "$RESULT_ID" "1024"
assert_success "CPU percent can be set" result_cpu_percent_set "$RESULT_ID" "82.5"
assert_success "Output can be set" result_output_set "$RESULT_ID" "Smoke test output"
assert_equals "Updated duration is retrievable" "1250" "$(result_duration_ms_get "$RESULT_ID")"

assert_success "Result can transition to running" result_mark_running "$RESULT_ID"
assert_equals "Status becomes running" "$RESULT_STATUS_RUNNING" "$(result_status_get "$RESULT_ID")"

assert_success "Result can transition to completed" result_mark_completed "$RESULT_ID" "0"
assert_equals "Status becomes completed" "$RESULT_STATUS_COMPLETED" "$(result_status_get "$RESULT_ID")"
assert_equals "Exit code is stored" "0" "$(result_exit_code_get "$RESULT_ID")"

assert_success "Single result validates" result_validate "$RESULT_ID"
assert_success "Result repository validates" results_validate

ERRORS_BEFORE="$(errors_count)"
if result_set "$RESULT_ID" "not_a_real_field" "value" >/dev/null 2>&1; then
    fail "Invalid field is rejected"
else
    pass "Invalid field is rejected"
fi
ERRORS_AFTER="$(errors_count)"

if [ "$ERRORS_AFTER" -gt "$ERRORS_BEFORE" ]; then
    pass "Invalid field creates an Error Repository entry"
else
    fail "Invalid field creates an Error Repository entry"
fi

LAST_ERROR_ID="$(error_last || true)"
assert_nonempty "Last error ID is available" "$LAST_ERROR_ID"

if [ -n "$LAST_ERROR_ID" ]; then
    assert_success "Last error object validates" error_validate "$LAST_ERROR_ID"
fi

ERRORS_BEFORE="$(errors_count)"
if result_create \
    "not-a-provider" \
    "smoke-test-model" \
    "$DEFAULT_PROFILE" \
    "$WORKLOAD_REASONING" \
    "prompt" >/dev/null 2>&1
then
    fail "Invalid provider is rejected"
else
    pass "Invalid provider is rejected"
fi
ERRORS_AFTER="$(errors_count)"

if [ "$ERRORS_AFTER" -gt "$ERRORS_BEFORE" ]; then
    pass "Invalid provider creates an Error Repository entry"
else
    fail "Invalid provider creates an Error Repository entry"
fi

ERRORS_BEFORE="$(errors_count)"
if result_create \
    "$DEFAULT_PROVIDER" \
    "smoke-test-model" \
    "$DEFAULT_PROFILE" \
    "not-a-workload" \
    "prompt" >/dev/null 2>&1
then
    fail "Invalid workload is rejected"
else
    pass "Invalid workload is rejected"
fi
ERRORS_AFTER="$(errors_count)"

if [ "$ERRORS_AFTER" -gt "$ERRORS_BEFORE" ]; then
    pass "Invalid workload creates an Error Repository entry"
else
    fail "Invalid workload creates an Error Repository entry"
fi

assert_equals "Filter by provider finds result" "$RESULT_ID" "$(results_by_provider "$DEFAULT_PROVIDER")"
assert_equals "Filter by workload finds result" "$RESULT_ID" "$(results_by_workload "$WORKLOAD_REASONING")"
assert_equals "Filter by status finds result" "$RESULT_ID" "$(results_by_status "$RESULT_STATUS_COMPLETED")"

JSON_OUTPUT="$(result_json "$RESULT_ID")"
assert_nonempty "Single-result JSON serialization returns data" "$JSON_OUTPUT"

if command -v python3 >/dev/null 2>&1; then
    if printf "%s" "$JSON_OUTPUT" | python3 -m json.tool >/dev/null 2>&1; then
        pass "Single-result JSON is valid"
    else
        fail "Single-result JSON is valid"
    fi

    if results_json | python3 -m json.tool >/dev/null 2>&1; then
        pass "Repository JSON is valid"
    else
        fail "Repository JSON is valid"
    fi
else
    printf "SKIP: JSON syntax validation (python3 not found)\n"
fi

assert_nonempty "Markdown serialization returns data" "$(result_markdown "$RESULT_ID")"
assert_nonempty "CSV serialization returns data" "$(result_csv "$RESULT_ID")"
assert_nonempty "Text serialization returns data" "$(result_text "$RESULT_ID")"

JSON_FILE="${TEST_DIR}/.test-results.json"
CSV_FILE="${TEST_DIR}/.test-results.csv"
MARKDOWN_FILE="${TEST_DIR}/.test-results.md"
TEXT_FILE="${TEST_DIR}/.test-results.txt"

assert_success "JSON repository export succeeds" results_save_json "$JSON_FILE"
assert_success "CSV repository export succeeds" results_save_csv "$CSV_FILE"
assert_success "Markdown repository export succeeds" results_save_markdown "$MARKDOWN_FILE"
assert_success "Text repository export succeeds" results_save_text "$TEXT_FILE"

assert_file_nonempty "JSON export is non-empty" "$JSON_FILE"
assert_file_nonempty "CSV export is non-empty" "$CSV_FILE"
assert_file_nonempty "Markdown export is non-empty" "$MARKDOWN_FILE"
assert_file_nonempty "Text export is non-empty" "$TEXT_FILE"

assert_success "Result can be deleted" result_delete "$RESULT_ID"
assert_failure "Deleted result no longer exists" result_exists "$RESULT_ID"
assert_equals "Result count returns to zero" "0" "$(results_count)"

result_create \
    "$DEFAULT_PROVIDER" \
    "second-smoke-test-model" \
    "$DEFAULT_PROFILE" \
    "$WORKLOAD_CODING" \
    "Write a simple deterministic function." >/dev/null

SECOND_ID="$RESULT_LAST_ID"

assert_nonempty "Second result can be created" "$SECOND_ID"
assert_equals "Result count is one before reset" "1" "$(results_count)"

assert_success "Result repository reset succeeds" results_reset
assert_equals "Result count is zero after reset" "0" "$(results_count)"

assert_success "Error repository reset succeeds" errors_reset
assert_equals "Error count is zero after reset" "0" "$(errors_count)"

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