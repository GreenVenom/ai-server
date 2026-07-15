#!/usr/bin/env bash
#
# ============================================================
# Personal AI Platform
# Benchmark Framework
#
# File: test-reporting.sh
#
# Purpose:
#   Smoke-test reporting against deterministic Result objects.
#
# Usage:
#   ./benchmarks/tests/test-reporting.sh
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

assert_file_nonempty() {
    local d="$1"
    local f="$2"

    if [ -s "$f" ]; then pass "$d"; else fail "$d"; fi
}

cleanup() {
    rm -f \
        "${TEST_DIR}/.test-report.txt" \
        "${TEST_DIR}/.test-report.md" \
        "${TEST_DIR}/.test-report.json" \
        "${TEST_DIR}/.test-report.csv"
}
trap cleanup EXIT

printf "============================================================\n"
printf "Benchmark Framework Reporting Smoke Test\n"
printf "============================================================\n\n"

if source "${API_DIR}/reporting.sh"; then
    pass "reporting.sh loads"
else
    fail "reporting.sh loads"
    exit 1
fi

assert_success "Result repository resets" results_reset
assert_success "Error repository resets" errors_reset

# Result 1: completed
result_create \
    "$PROVIDER_OLLAMA" \
    "qwen3:14b" \
    "quick" \
    "$WORKLOAD_REASONING" \
    "prompt 1" >/dev/null
R1="$RESULT_LAST_ID"
result_duration_ms_set "$R1" "1000"
result_tokens_per_second_set "$R1" "20.0"
result_mark_completed "$R1" "0"

# Result 2: completed
result_create \
    "$PROVIDER_OLLAMA" \
    "gemma4:12b" \
    "quick" \
    "$WORKLOAD_CODING" \
    "prompt 2" >/dev/null
R2="$RESULT_LAST_ID"
result_duration_ms_set "$R2" "3000"
result_tokens_per_second_set "$R2" "40.0"
result_mark_completed "$R2" "0"

# Result 3: failed
result_create \
    "$PROVIDER_OLLAMA" \
    "qwen3:14b" \
    "standard" \
    "$WORKLOAD_REASONING" \
    "prompt 3" >/dev/null
R3="$RESULT_LAST_ID"
result_duration_ms_set "$R3" "2000"
result_mark_failed "$R3" "simulated failure" "30"

assert_equals "Total result count is 3" "3" "$(report_count_total)"
assert_equals "Completed count is 2" "2" "$(report_count_completed)"
assert_equals "Failed count is 1" "1" "$(report_count_failed)"
assert_equals "Skipped count is 0" "0" "$(report_count_skipped)"
assert_equals "Timeout count is 0" "0" "$(report_count_timeout)"
assert_equals "Cancelled count is 0" "0" "$(report_count_cancelled)"

assert_equals \
    "Average duration is 2000 ms" \
    "2000.000" \
    "$(report_average_duration_ms)"

assert_equals \
    "Average throughput uses populated values only" \
    "30.000" \
    "$(report_average_tokens_per_second)"

assert_equals \
    "qwen3 model count is 2" \
    "2" \
    "$(report_count_by_field_value "$RESULT_FIELD_MODEL" "qwen3:14b")"

assert_equals \
    "quick profile count is 2" \
    "2" \
    "$(report_count_by_field_value "$RESULT_FIELD_PROFILE" "quick")"

assert_nonempty "Text summary is generated" "$(report_summary_text)"
assert_nonempty "Markdown summary is generated" "$(report_summary_markdown)"
assert_nonempty "JSON summary is generated" "$(report_summary_json)"
assert_nonempty "CSV summary is generated" "$(report_summary_csv)"

if command -v python3 >/dev/null 2>&1; then
    if report_summary_json | python3 -m json.tool >/dev/null 2>&1; then
        pass "JSON report is valid"
    else
        fail "JSON report is valid"
    fi
fi

TEXT_FILE="${TEST_DIR}/.test-report.txt"
MD_FILE="${TEST_DIR}/.test-report.md"
JSON_FILE="${TEST_DIR}/.test-report.json"
CSV_FILE="${TEST_DIR}/.test-report.csv"

assert_success "Text report saves" report_save_text "$TEXT_FILE"
assert_success "Markdown report saves" report_save_markdown "$MD_FILE"
assert_success "JSON report saves" report_save_json "$JSON_FILE"
assert_success "CSV report saves" report_save_csv "$CSV_FILE"

assert_file_nonempty "Text report file is non-empty" "$TEXT_FILE"
assert_file_nonempty "Markdown report file is non-empty" "$MD_FILE"
assert_file_nonempty "JSON report file is non-empty" "$JSON_FILE"
assert_file_nonempty "CSV report file is non-empty" "$CSV_FILE"

assert_success "Result repository remains valid" results_validate

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
