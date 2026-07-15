#!/usr/bin/env bash
#
# ============================================================
# Personal AI Platform
# Benchmark Framework
#
# File: reporting.sh
#
# Purpose:
#   Builds human-readable and machine-readable benchmark reports
#   from the Result Repository.
#
# Responsibilities:
#   - Repository summary metrics
#   - Status counts
#   - Average duration and throughput
#   - Grouped summaries
#   - Text, Markdown, JSON, and CSV report output
#
# Design:
#   - Consumes results.sh only
#   - Does not call providers, models, prompts, or executor
#   - Bash 3.2 compatible
# ============================================================

[[ -n "${BENCHMARK_REPORTING_LOADED:-}" ]] && return 0
BENCHMARK_REPORTING_LOADED=1

REPORTING_API_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=/dev/null
source "${REPORTING_API_DIR}/results.sh"

# ------------------------------------------------------------
# Internal numeric helpers
# ------------------------------------------------------------

_reporting_average() {
    local sum="$1"
    local count="$2"

    if [ "$count" -eq 0 ]; then
        printf "0.000\n"
        return 0
    fi

    if command -v python3 >/dev/null 2>&1; then
        python3 - "$sum" "$count" <<'PY'
import sys
print(f"{float(sys.argv[1]) / int(sys.argv[2]):.3f}")
PY
        return $?
    fi

    awk "BEGIN { printf \"%.3f\n\", (${sum})/(${count}) }"
}

_reporting_json_escape() {
    local value="${1-}"

    value=${value//\\/\\\\}
    value=${value//\"/\\\"}
    value=${value//$'\n'/\\n}
    value=${value//$'\r'/\\r}
    value=${value//$'\t'/\\t}

    printf "%s" "$value"
}

_reporting_csv_escape() {
    local value="${1-}"
    value=${value//\"/\"\"}
    printf '"%s"' "$value"
}

# ------------------------------------------------------------
# Counts
# ------------------------------------------------------------

report_count_total() {
    results_count
}

report_count_status() {
    local status="$1"
    local i=0
    local count=0

    result_status_valid "$status" || return "$EXIT_INVALID_ARGUMENT"

    while [ "$i" -lt "$RESULT_COUNT" ]; do
        if [ "${RESULT_STATUS_VALUES[$i]}" = "$status" ]; then
            count=$((count + 1))
        fi
        i=$((i + 1))
    done

    printf "%s\n" "$count"
}

report_count_completed() {
    report_count_status "$RESULT_STATUS_COMPLETED"
}

report_count_failed() {
    report_count_status "$RESULT_STATUS_FAILED"
}

report_count_skipped() {
    report_count_status "$RESULT_STATUS_SKIPPED"
}

report_count_timeout() {
    report_count_status "$RESULT_STATUS_TIMEOUT"
}

report_count_cancelled() {
    report_count_status "$RESULT_STATUS_CANCELLED"
}

# ------------------------------------------------------------
# Aggregate metrics
# ------------------------------------------------------------

report_average_duration_ms() {
    local i=0
    local count=0
    local sum=0
    local value

    while [ "$i" -lt "$RESULT_COUNT" ]; do
        value="${RESULT_DURATION_MS_VALUES[$i]-}"

        if [ -n "$value" ]; then
            sum=$((sum + value))
            count=$((count + 1))
        fi

        i=$((i + 1))
    done

    _reporting_average "$sum" "$count"
}

report_average_tokens_per_second() {
    local i=0
    local count=0
    local sum="0"
    local value

    while [ "$i" -lt "$RESULT_COUNT" ]; do
        value="${RESULT_TOKENS_PER_SECOND_VALUES[$i]-}"

        if [ -n "$value" ]; then
            if command -v python3 >/dev/null 2>&1; then
                sum="$(
                    python3 - "$sum" "$value" <<'PY'
import sys
print(float(sys.argv[1]) + float(sys.argv[2]))
PY
                )"
            else
                sum="$(awk "BEGIN { print (${sum}) + (${value}) }")"
            fi
            count=$((count + 1))
        fi

        i=$((i + 1))
    done

    _reporting_average "$sum" "$count"
}

# ------------------------------------------------------------
# Distinct value helpers
# ------------------------------------------------------------

_report_distinct_field() {
    local field="$1"
    local i=0
    local value
    local seen=""

    while [ "$i" -lt "$RESULT_COUNT" ]; do
        value="$(result_get "${RESULT_IDS[$i]}" "$field")"

        if [ -n "$value" ]; then
            case "
${seen}
" in
                *"
${value}
"*)
                    ;;
                *)
                    printf "%s\n" "$value"
                    seen="${seen}
${value}"
                    ;;
            esac
        fi

        i=$((i + 1))
    done
}

report_models() {
    _report_distinct_field "$RESULT_FIELD_MODEL"
}

report_providers() {
    _report_distinct_field "$RESULT_FIELD_PROVIDER"
}

report_workloads() {
    _report_distinct_field "$RESULT_FIELD_WORKLOAD"
}

report_profiles() {
    _report_distinct_field "$RESULT_FIELD_PROFILE"
}

# ------------------------------------------------------------
# Grouped counts
# ------------------------------------------------------------

report_count_by_field_value() {
    local field="$1"
    local target="$2"
    local i=0
    local count=0
    local value

    result_field_valid "$field" || return "$EXIT_INVALID_ARGUMENT"

    while [ "$i" -lt "$RESULT_COUNT" ]; do
        value="$(result_get "${RESULT_IDS[$i]}" "$field")"
        if [ "$value" = "$target" ]; then
            count=$((count + 1))
        fi
        i=$((i + 1))
    done

    printf "%s\n" "$count"
}

# ------------------------------------------------------------
# Text summary
# ------------------------------------------------------------

report_summary_text() {
    printf "Benchmark Report Summary\n"
    printf "========================\n"
    printf "Total Results           : %s\n" "$(report_count_total)"
    printf "Completed               : %s\n" "$(report_count_completed)"
    printf "Failed                  : %s\n" "$(report_count_failed)"
    printf "Skipped                 : %s\n" "$(report_count_skipped)"
    printf "Timeout                 : %s\n" "$(report_count_timeout)"
    printf "Cancelled               : %s\n" "$(report_count_cancelled)"
    printf "Average Duration (ms)   : %s\n" "$(report_average_duration_ms)"
    printf "Average Tokens / second : %s\n" "$(report_average_tokens_per_second)"
}

# ------------------------------------------------------------
# Markdown report
# ------------------------------------------------------------

report_summary_markdown() {
    cat <<EOF
# Benchmark Report

## Summary

| Metric | Value |
|---|---:|
| Total Results | $(report_count_total) |
| Completed | $(report_count_completed) |
| Failed | $(report_count_failed) |
| Skipped | $(report_count_skipped) |
| Timeout | $(report_count_timeout) |
| Cancelled | $(report_count_cancelled) |
| Average Duration (ms) | $(report_average_duration_ms) |
| Average Tokens / second | $(report_average_tokens_per_second) |

## Results
EOF

    local i=0
    while [ "$i" -lt "$RESULT_COUNT" ]; do
        result_markdown "${RESULT_IDS[$i]}"
        i=$((i + 1))
    done
}

# ------------------------------------------------------------
# JSON report
# ------------------------------------------------------------

report_summary_json() {
    printf '{'
    printf '"summary":{'
    printf '"total":%s,' "$(report_count_total)"
    printf '"completed":%s,' "$(report_count_completed)"
    printf '"failed":%s,' "$(report_count_failed)"
    printf '"skipped":%s,' "$(report_count_skipped)"
    printf '"timeout":%s,' "$(report_count_timeout)"
    printf '"cancelled":%s,' "$(report_count_cancelled)"
    printf '"average_duration_ms":%s,' "$(report_average_duration_ms)"
    printf '"average_tokens_per_second":%s' "$(report_average_tokens_per_second)"
    printf '},'
    printf '"results":'
    results_json | tr -d '\n'
    printf '}\n'
}

# ------------------------------------------------------------
# CSV summary
# ------------------------------------------------------------

report_summary_csv() {
    printf '%s\n' \
        'metric,value' \
        "total,$(report_count_total)" \
        "completed,$(report_count_completed)" \
        "failed,$(report_count_failed)" \
        "skipped,$(report_count_skipped)" \
        "timeout,$(report_count_timeout)" \
        "cancelled,$(report_count_cancelled)" \
        "average_duration_ms,$(report_average_duration_ms)" \
        "average_tokens_per_second,$(report_average_tokens_per_second)"
}

# ------------------------------------------------------------
# Persistence helpers
# ------------------------------------------------------------

report_save_text() {
    local file="$1"
    [ -n "$file" ] || return "$EXIT_INVALID_ARGUMENT"
    report_summary_text > "$file"
}

report_save_markdown() {
    local file="$1"
    [ -n "$file" ] || return "$EXIT_INVALID_ARGUMENT"
    report_summary_markdown > "$file"
}

report_save_json() {
    local file="$1"
    [ -n "$file" ] || return "$EXIT_INVALID_ARGUMENT"
    report_summary_json > "$file"
}

report_save_csv() {
    local file="$1"
    [ -n "$file" ] || return "$EXIT_INVALID_ARGUMENT"
    report_summary_csv > "$file"
}
