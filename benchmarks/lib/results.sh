#!/usr/bin/env bash
#
# ============================================================
# Personal AI Platform
# Benchmark Framework
#
# File: results.sh
#
# Purpose:
#   Implements the Result Repository and public Result API.
#
# Responsibilities:
#   - Structured benchmark result creation
#   - Result repository lifecycle
#   - Object identity
#   - CRUD-style repository operations
#   - Result lifecycle management
#   - Validation integration
#   - Filtering and querying
#   - Text, JSON, Markdown, and CSV serialization
#   - Repository export helpers
#
# Design:
#   - Conforms to ADR-0007 (Benchmark Framework Architecture)
#   - Conforms to ADR-0009 (Standardized Repository Pattern)
#   - Uses Bash 3.2-compatible indexed arrays for macOS
#   - Delegates schema and enums to definitions.sh
#   - Delegates primitive and business validation to validators.sh
#   - Integrates with the Error Framework through errors.sh
#
# Version: 1.0.0
#
# Notes:
#   Bash function return values are limited to 0-255. Framework
#   error codes are stored in structured error objects while
#   functions return standard shell-compatible status codes.
# ============================================================

[[ -n "${BENCHMARK_RESULTS_LOADED:-}" ]] && return 0
BENCHMARK_RESULTS_LOADED=1

# ------------------------------------------------------------
# Dependency discovery
# ------------------------------------------------------------

RESULTS_API_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESULTS_LIB_DIR="$(cd "${RESULTS_API_DIR}/.." && pwd)"
RESULTS_CORE_DIR="${RESULTS_LIB_DIR}/core"

# shellcheck source=/dev/null
source "${RESULTS_CORE_DIR}/definitions.sh"

# shellcheck source=/dev/null
source "${RESULTS_CORE_DIR}/validators.sh"

# shellcheck source=/dev/null
source "${RESULTS_API_DIR}/errors.sh"

# ------------------------------------------------------------
# Compatibility defaults
# ------------------------------------------------------------

: "${EXIT_SUCCESS:=0}"
: "${EXIT_FAILURE:=1}"
: "${EXIT_INVALID_ARGUMENT:=2}"
: "${EXIT_INVALID_STATE:=3}"
: "${EXIT_SERIALIZATION_FAILED:=40}"

: "${ERR_INVALID_ARGUMENT:=1000}"
: "${ERR_INVALID_RESULT:=1004}"
: "${ERR_SERIALIZATION:=4000}"
: "${ERR_INTERNAL:=9000}"

: "${ERROR_CATEGORY_VALIDATION:=validation}"
: "${ERROR_CATEGORY_SERIALIZATION:=serialization}"
: "${ERROR_CATEGORY_INTERNAL:=internal}"

: "${ERROR_SEVERITY_ERROR:=error}"

# ------------------------------------------------------------
# Repository metadata
# ------------------------------------------------------------

readonly RESULT_REPOSITORY_RUNTIME_VERSION="1.0"
readonly RESULT_ID_PADDING=6

# ------------------------------------------------------------
# Repository storage
#
# Bash 3.2 does not support associative arrays. The repository
# uses parallel indexed arrays, one slot per Result object.
# RESULT_IDS is the canonical repository index.
# ------------------------------------------------------------

RESULT_IDS=()
RESULT_CREATED_VALUES=()
RESULT_TIMESTAMP_VALUES=()
RESULT_STATUS_VALUES=()
RESULT_PROVIDER_VALUES=()
RESULT_MODEL_VALUES=()
RESULT_PROFILE_VALUES=()
RESULT_WORKLOAD_VALUES=()
RESULT_PROMPT_VALUES=()
RESULT_DURATION_MS_VALUES=()
RESULT_DURATION_SECONDS_VALUES=()
RESULT_TOKENS_VALUES=()
RESULT_TOKENS_PER_SECOND_VALUES=()
RESULT_MEMORY_MB_VALUES=()
RESULT_CPU_PERCENT_VALUES=()
RESULT_EXIT_CODE_VALUES=()
RESULT_ERROR_VALUES=()
RESULT_OUTPUT_VALUES=()

RESULT_COUNT=0
RESULT_SEQUENCE=0
RESULT_LAST_ID=""

# ------------------------------------------------------------
# Internal helpers
# ------------------------------------------------------------

_result_now() {
    date -u +"${RESULT_TIMESTAMP_FORMAT}"
}

_result_generate_id() {
    RESULT_SEQUENCE=$((RESULT_SEQUENCE + 1))
    printf "%s-%0*d\n" \
        "${RESULT_ID_PREFIX}" \
        "${RESULT_ID_PADDING}" \
        "${RESULT_SEQUENCE}"
}

_result_index_of() {
    local id="$1"
    local i=0

    while [ "$i" -lt "${#RESULT_IDS[@]}" ]; do
        if [ "${RESULT_IDS[$i]}" = "$id" ]; then
            printf "%s\n" "$i"
            return 0
        fi
        i=$((i + 1))
    done

    return 1
}

_result_json_escape() {
    local value="${1-}"

    value=${value//\\/\\\\}
    value=${value//\"/\\\"}
    value=${value//$'\n'/\\n}
    value=${value//$'\r'/\\r}
    value=${value//$'\t'/\\t}

    printf "%s" "$value"
}

_result_markdown_escape() {
    local value="${1-}"

    value=${value//$'\r'/}
    value=${value//$'\n'/<br>}
    value=${value//|/\\|}

    printf "%s" "$value"
}

_result_csv_escape() {
    local value="${1-}"

    value=${value//\"/\"\"}
    printf '"%s"' "$value"
}

_result_shift_left_from() {
    local start="$1"
    local i="$start"
    local last_index=$((RESULT_COUNT - 1))

    while [ "$i" -lt "$last_index" ]; do
        RESULT_IDS[$i]="${RESULT_IDS[$((i + 1))]}"
        RESULT_CREATED_VALUES[$i]="${RESULT_CREATED_VALUES[$((i + 1))]}"
        RESULT_TIMESTAMP_VALUES[$i]="${RESULT_TIMESTAMP_VALUES[$((i + 1))]}"
        RESULT_STATUS_VALUES[$i]="${RESULT_STATUS_VALUES[$((i + 1))]}"
        RESULT_PROVIDER_VALUES[$i]="${RESULT_PROVIDER_VALUES[$((i + 1))]}"
        RESULT_MODEL_VALUES[$i]="${RESULT_MODEL_VALUES[$((i + 1))]}"
        RESULT_PROFILE_VALUES[$i]="${RESULT_PROFILE_VALUES[$((i + 1))]}"
        RESULT_WORKLOAD_VALUES[$i]="${RESULT_WORKLOAD_VALUES[$((i + 1))]}"
        RESULT_PROMPT_VALUES[$i]="${RESULT_PROMPT_VALUES[$((i + 1))]}"
        RESULT_DURATION_MS_VALUES[$i]="${RESULT_DURATION_MS_VALUES[$((i + 1))]}"
        RESULT_DURATION_SECONDS_VALUES[$i]="${RESULT_DURATION_SECONDS_VALUES[$((i + 1))]}"
        RESULT_TOKENS_VALUES[$i]="${RESULT_TOKENS_VALUES[$((i + 1))]}"
        RESULT_TOKENS_PER_SECOND_VALUES[$i]="${RESULT_TOKENS_PER_SECOND_VALUES[$((i + 1))]}"
        RESULT_MEMORY_MB_VALUES[$i]="${RESULT_MEMORY_MB_VALUES[$((i + 1))]}"
        RESULT_CPU_PERCENT_VALUES[$i]="${RESULT_CPU_PERCENT_VALUES[$((i + 1))]}"
        RESULT_EXIT_CODE_VALUES[$i]="${RESULT_EXIT_CODE_VALUES[$((i + 1))]}"
        RESULT_ERROR_VALUES[$i]="${RESULT_ERROR_VALUES[$((i + 1))]}"
        RESULT_OUTPUT_VALUES[$i]="${RESULT_OUTPUT_VALUES[$((i + 1))]}"

        i=$((i + 1))
    done

    unset 'RESULT_IDS[$last_index]'
    unset 'RESULT_CREATED_VALUES[$last_index]'
    unset 'RESULT_TIMESTAMP_VALUES[$last_index]'
    unset 'RESULT_STATUS_VALUES[$last_index]'
    unset 'RESULT_PROVIDER_VALUES[$last_index]'
    unset 'RESULT_MODEL_VALUES[$last_index]'
    unset 'RESULT_PROFILE_VALUES[$last_index]'
    unset 'RESULT_WORKLOAD_VALUES[$last_index]'
    unset 'RESULT_PROMPT_VALUES[$last_index]'
    unset 'RESULT_DURATION_MS_VALUES[$last_index]'
    unset 'RESULT_DURATION_SECONDS_VALUES[$last_index]'
    unset 'RESULT_TOKENS_VALUES[$last_index]'
    unset 'RESULT_TOKENS_PER_SECOND_VALUES[$last_index]'
    unset 'RESULT_MEMORY_MB_VALUES[$last_index]'
    unset 'RESULT_CPU_PERCENT_VALUES[$last_index]'
    unset 'RESULT_EXIT_CODE_VALUES[$last_index]'
    unset 'RESULT_ERROR_VALUES[$last_index]'
    unset 'RESULT_OUTPUT_VALUES[$last_index]'
}

_result_get_by_index() {
    local index="$1"
    local field="$2"

    case "$field" in
        "$RESULT_FIELD_ID")                printf "%s\n" "${RESULT_IDS[$index]-}" ;;
        "$RESULT_FIELD_CREATED")           printf "%s\n" "${RESULT_CREATED_VALUES[$index]-}" ;;
        "$RESULT_FIELD_TIMESTAMP")         printf "%s\n" "${RESULT_TIMESTAMP_VALUES[$index]-}" ;;
        "$RESULT_FIELD_STATUS")            printf "%s\n" "${RESULT_STATUS_VALUES[$index]-}" ;;
        "$RESULT_FIELD_PROVIDER")          printf "%s\n" "${RESULT_PROVIDER_VALUES[$index]-}" ;;
        "$RESULT_FIELD_MODEL")             printf "%s\n" "${RESULT_MODEL_VALUES[$index]-}" ;;
        "$RESULT_FIELD_PROFILE")           printf "%s\n" "${RESULT_PROFILE_VALUES[$index]-}" ;;
        "$RESULT_FIELD_WORKLOAD")          printf "%s\n" "${RESULT_WORKLOAD_VALUES[$index]-}" ;;
        "$RESULT_FIELD_PROMPT")            printf "%s\n" "${RESULT_PROMPT_VALUES[$index]-}" ;;
        "$RESULT_FIELD_DURATION_MS")       printf "%s\n" "${RESULT_DURATION_MS_VALUES[$index]-}" ;;
        "$RESULT_FIELD_DURATION_SECONDS")  printf "%s\n" "${RESULT_DURATION_SECONDS_VALUES[$index]-}" ;;
        "$RESULT_FIELD_TOKENS")            printf "%s\n" "${RESULT_TOKENS_VALUES[$index]-}" ;;
        "$RESULT_FIELD_TOKENS_PER_SECOND") printf "%s\n" "${RESULT_TOKENS_PER_SECOND_VALUES[$index]-}" ;;
        "$RESULT_FIELD_MEMORY_MB")         printf "%s\n" "${RESULT_MEMORY_MB_VALUES[$index]-}" ;;
        "$RESULT_FIELD_CPU_PERCENT")       printf "%s\n" "${RESULT_CPU_PERCENT_VALUES[$index]-}" ;;
        "$RESULT_FIELD_EXIT_CODE")         printf "%s\n" "${RESULT_EXIT_CODE_VALUES[$index]-}" ;;
        "$RESULT_FIELD_ERROR")             printf "%s\n" "${RESULT_ERROR_VALUES[$index]-}" ;;
        "$RESULT_FIELD_OUTPUT")            printf "%s\n" "${RESULT_OUTPUT_VALUES[$index]-}" ;;
        *)
            return "$EXIT_INVALID_ARGUMENT"
            ;;
    esac

    return "$EXIT_SUCCESS"
}

_result_set_by_index() {
    local index="$1"
    local field="$2"
    local value="${3-}"

    case "$field" in
        "$RESULT_FIELD_ID")
            return "$EXIT_INVALID_STATE"
            ;;
        "$RESULT_FIELD_CREATED")           RESULT_CREATED_VALUES[$index]="$value" ;;
        "$RESULT_FIELD_TIMESTAMP")         RESULT_TIMESTAMP_VALUES[$index]="$value" ;;
        "$RESULT_FIELD_STATUS")            RESULT_STATUS_VALUES[$index]="$value" ;;
        "$RESULT_FIELD_PROVIDER")          RESULT_PROVIDER_VALUES[$index]="$value" ;;
        "$RESULT_FIELD_MODEL")             RESULT_MODEL_VALUES[$index]="$value" ;;
        "$RESULT_FIELD_PROFILE")           RESULT_PROFILE_VALUES[$index]="$value" ;;
        "$RESULT_FIELD_WORKLOAD")          RESULT_WORKLOAD_VALUES[$index]="$value" ;;
        "$RESULT_FIELD_PROMPT")            RESULT_PROMPT_VALUES[$index]="$value" ;;
        "$RESULT_FIELD_DURATION_MS")       RESULT_DURATION_MS_VALUES[$index]="$value" ;;
        "$RESULT_FIELD_DURATION_SECONDS")  RESULT_DURATION_SECONDS_VALUES[$index]="$value" ;;
        "$RESULT_FIELD_TOKENS")            RESULT_TOKENS_VALUES[$index]="$value" ;;
        "$RESULT_FIELD_TOKENS_PER_SECOND") RESULT_TOKENS_PER_SECOND_VALUES[$index]="$value" ;;
        "$RESULT_FIELD_MEMORY_MB")         RESULT_MEMORY_MB_VALUES[$index]="$value" ;;
        "$RESULT_FIELD_CPU_PERCENT")       RESULT_CPU_PERCENT_VALUES[$index]="$value" ;;
        "$RESULT_FIELD_EXIT_CODE")         RESULT_EXIT_CODE_VALUES[$index]="$value" ;;
        "$RESULT_FIELD_ERROR")             RESULT_ERROR_VALUES[$index]="$value" ;;
        "$RESULT_FIELD_OUTPUT")            RESULT_OUTPUT_VALUES[$index]="$value" ;;
        *)
            return "$EXIT_INVALID_ARGUMENT"
            ;;
    esac

    return "$EXIT_SUCCESS"
}

_result_create_error() {
    local function_name="$1"
    local message="$2"
    local details="${3-}"
    local suggestion="${4-}"

    error_create \
        "Result Repository" \
        "$function_name" \
        "$ERR_INVALID_RESULT" \
        "$EXIT_INVALID_ARGUMENT" \
        "$ERROR_CATEGORY_VALIDATION" \
        "$ERROR_SEVERITY_ERROR" \
        "$message" \
        "$details" \
        "$suggestion" >/dev/null
}

_result_serialization_error() {
    local function_name="$1"
    local message="$2"
    local details="${3-}"

    error_create \
        "Result Repository" \
        "$function_name" \
        "$ERR_SERIALIZATION" \
        "$EXIT_SERIALIZATION_FAILED" \
        "$ERROR_CATEGORY_SERIALIZATION" \
        "$ERROR_SEVERITY_ERROR" \
        "$message" \
        "$details" \
        "Verify the destination path and result data." >/dev/null
}

_result_validate_field_value() {
    local field="$1"
    local value="${2-}"

    if ! result_field_valid "$field"; then
        return 1
    fi

    # Empty values are allowed for optional fields.
    if [ -z "$value" ]; then
        return 0
    fi

    result_value_valid "$field" "$value"
}

_result_required_fields_present_by_index() {
    local index="$1"
    local field
    local value

    for field in "${RESULT_FIELD_ENUM[@]}"; do
        if result_field_required "$field"; then
            value="$(_result_get_by_index "$index" "$field")"
            [ -n "$value" ] || return 1
        fi
    done

    return 0
}

# ------------------------------------------------------------
# Repository predicates
# ------------------------------------------------------------

results_empty() {
    [ "$RESULT_COUNT" -eq 0 ]
}

results_exists() {
    local id="$1"
    _result_index_of "$id" >/dev/null 2>&1
}

result_exists() {
    results_exists "$1"
}

# ------------------------------------------------------------
# Repository queries
# ------------------------------------------------------------

results_count() {
    printf "%s\n" "$RESULT_COUNT"
}

results_ids() {
    [ "$RESULT_COUNT" -gt 0 ] || return 0
    printf "%s\n" "${RESULT_IDS[@]}"
}

result_last() {
    [ -n "$RESULT_LAST_ID" ] || return 1
    printf "%s\n" "$RESULT_LAST_ID"
}

result_first() {
    [ "$RESULT_COUNT" -gt 0 ] || return 1
    printf "%s\n" "${RESULT_IDS[0]}"
}

# ------------------------------------------------------------
# Repository lifecycle
# ------------------------------------------------------------

results_clear_all() {
    RESULT_IDS=()
    RESULT_CREATED_VALUES=()
    RESULT_TIMESTAMP_VALUES=()
    RESULT_STATUS_VALUES=()
    RESULT_PROVIDER_VALUES=()
    RESULT_MODEL_VALUES=()
    RESULT_PROFILE_VALUES=()
    RESULT_WORKLOAD_VALUES=()
    RESULT_PROMPT_VALUES=()
    RESULT_DURATION_MS_VALUES=()
    RESULT_DURATION_SECONDS_VALUES=()
    RESULT_TOKENS_VALUES=()
    RESULT_TOKENS_PER_SECOND_VALUES=()
    RESULT_MEMORY_MB_VALUES=()
    RESULT_CPU_PERCENT_VALUES=()
    RESULT_EXIT_CODE_VALUES=()
    RESULT_ERROR_VALUES=()
    RESULT_OUTPUT_VALUES=()

    RESULT_COUNT=0
    RESULT_LAST_ID=""

    return "$EXIT_SUCCESS"
}

results_reset() {
    results_clear_all
    RESULT_SEQUENCE=0
    return "$EXIT_SUCCESS"
}

# ------------------------------------------------------------
# Object lifecycle
# ------------------------------------------------------------

result_create() {
    local provider="$1"
    local model="$2"
    local profile="${3:-$DEFAULT_PROFILE}"
    local workload="${4-}"
    local prompt="${5-}"

    if ! provider_valid "$provider"; then
        _result_create_error \
            "result_create" \
            "Invalid provider." \
            "Provider '${provider}' is not defined by the Benchmark Framework." \
            "Use a provider from PROVIDER_ENUM."
        return "$EXIT_INVALID_ARGUMENT"
    fi

    if [ -z "$model" ]; then
        _result_create_error \
            "result_create" \
            "Model is required." \
            "A Result object cannot be created without a model identifier." \
            "Provide the provider-specific model name."
        return "$EXIT_INVALID_ARGUMENT"
    fi

    if [ -n "$workload" ] && ! workload_valid "$workload"; then
        _result_create_error \
            "result_create" \
            "Invalid workload." \
            "Workload '${workload}' is not defined by the Benchmark Framework." \
            "Use a workload from WORKLOAD_ENUM."
        return "$EXIT_INVALID_ARGUMENT"
    fi

    local id
    local index
    local now

    id="$(_result_generate_id)"
    index="$RESULT_COUNT"
    now="$(_result_now)"

    RESULT_IDS[$index]="$id"
    RESULT_CREATED_VALUES[$index]="$now"
    RESULT_TIMESTAMP_VALUES[$index]="$now"
    RESULT_STATUS_VALUES[$index]="$DEFAULT_RESULT_STATUS"
    RESULT_PROVIDER_VALUES[$index]="$provider"
    RESULT_MODEL_VALUES[$index]="$model"
    RESULT_PROFILE_VALUES[$index]="$profile"
    RESULT_WORKLOAD_VALUES[$index]="$workload"
    RESULT_PROMPT_VALUES[$index]="$prompt"
    RESULT_DURATION_MS_VALUES[$index]=""
    RESULT_DURATION_SECONDS_VALUES[$index]=""
    RESULT_TOKENS_VALUES[$index]=""
    RESULT_TOKENS_PER_SECOND_VALUES[$index]=""
    RESULT_MEMORY_MB_VALUES[$index]=""
    RESULT_CPU_PERCENT_VALUES[$index]=""
    RESULT_EXIT_CODE_VALUES[$index]=""
    RESULT_ERROR_VALUES[$index]=""
    RESULT_OUTPUT_VALUES[$index]=""

    RESULT_COUNT=$((RESULT_COUNT + 1))
    RESULT_LAST_ID="$id"

    printf "%s\n" "$id"
    return "$EXIT_SUCCESS"
}

result_delete() {
    local id="$1"
    local index

    index="$(_result_index_of "$id")" || return "$EXIT_FAILURE"

    _result_shift_left_from "$index"

    RESULT_COUNT=$((RESULT_COUNT - 1))

    if [ "$RESULT_COUNT" -eq 0 ]; then
        RESULT_LAST_ID=""
    else
        RESULT_LAST_ID="${RESULT_IDS[$((RESULT_COUNT - 1))]}"
    fi

    return "$EXIT_SUCCESS"
}

result_clear() {
    result_delete "$1"
}

# ------------------------------------------------------------
# Object field access
# ------------------------------------------------------------

result_get() {
    local id="$1"
    local field="$2"
    local index

    result_field_valid "$field" || return "$EXIT_INVALID_ARGUMENT"
    index="$(_result_index_of "$id")" || return "$EXIT_FAILURE"

    _result_get_by_index "$index" "$field"
}

result_set() {
    local id="$1"
    local field="$2"
    local value="${3-}"
    local index

    result_field_valid "$field" || {
        _result_create_error \
            "result_set" \
            "Invalid Result field." \
            "Field '${field}' is not defined in RESULT_FIELD_ENUM." \
            "Use a field defined by the framework specification."
        return "$EXIT_INVALID_ARGUMENT"
    }

    if [ "$field" = "$RESULT_FIELD_ID" ]; then
        _result_create_error \
            "result_set" \
            "Result identifiers are immutable." \
            "The '${RESULT_FIELD_ID}' field cannot be modified after creation." \
            "Create a new Result object instead."
        return "$EXIT_INVALID_STATE"
    fi

    index="$(_result_index_of "$id")" || return "$EXIT_FAILURE"

    if ! _result_validate_field_value "$field" "$value"; then
        _result_create_error \
            "result_set" \
            "Invalid Result field value." \
            "Field '${field}' rejected value '${value}'." \
            "Use a value compatible with the Result schema."
        return "$EXIT_INVALID_ARGUMENT"
    fi

    _result_set_by_index "$index" "$field" "$value"
}

# ------------------------------------------------------------
# Typed getters
# ------------------------------------------------------------

result_id_get()                { result_get "$1" "$RESULT_FIELD_ID"; }
result_created_get()           { result_get "$1" "$RESULT_FIELD_CREATED"; }
result_timestamp_get()         { result_get "$1" "$RESULT_FIELD_TIMESTAMP"; }
result_status_get()            { result_get "$1" "$RESULT_FIELD_STATUS"; }
result_provider_get()          { result_get "$1" "$RESULT_FIELD_PROVIDER"; }
result_model_get()             { result_get "$1" "$RESULT_FIELD_MODEL"; }
result_profile_get()           { result_get "$1" "$RESULT_FIELD_PROFILE"; }
result_workload_get()          { result_get "$1" "$RESULT_FIELD_WORKLOAD"; }
result_prompt_get()            { result_get "$1" "$RESULT_FIELD_PROMPT"; }
result_duration_ms_get()       { result_get "$1" "$RESULT_FIELD_DURATION_MS"; }
result_duration_seconds_get()  { result_get "$1" "$RESULT_FIELD_DURATION_SECONDS"; }
result_tokens_get()            { result_get "$1" "$RESULT_FIELD_TOKENS"; }
result_tokens_per_second_get() { result_get "$1" "$RESULT_FIELD_TOKENS_PER_SECOND"; }
result_memory_mb_get()         { result_get "$1" "$RESULT_FIELD_MEMORY_MB"; }
result_cpu_percent_get()       { result_get "$1" "$RESULT_FIELD_CPU_PERCENT"; }
result_exit_code_get()         { result_get "$1" "$RESULT_FIELD_EXIT_CODE"; }
result_error_get()             { result_get "$1" "$RESULT_FIELD_ERROR"; }
result_output_get()            { result_get "$1" "$RESULT_FIELD_OUTPUT"; }

# ------------------------------------------------------------
# Typed setters
# ------------------------------------------------------------

result_created_set()           { result_set "$1" "$RESULT_FIELD_CREATED" "$2"; }
result_timestamp_set()         { result_set "$1" "$RESULT_FIELD_TIMESTAMP" "$2"; }
result_status_set()            { result_set "$1" "$RESULT_FIELD_STATUS" "$2"; }
result_provider_set()          { result_set "$1" "$RESULT_FIELD_PROVIDER" "$2"; }
result_model_set()             { result_set "$1" "$RESULT_FIELD_MODEL" "$2"; }
result_profile_set()           { result_set "$1" "$RESULT_FIELD_PROFILE" "$2"; }
result_workload_set()          { result_set "$1" "$RESULT_FIELD_WORKLOAD" "$2"; }
result_prompt_set()            { result_set "$1" "$RESULT_FIELD_PROMPT" "$2"; }
result_duration_ms_set()       { result_set "$1" "$RESULT_FIELD_DURATION_MS" "$2"; }
result_duration_seconds_set()  { result_set "$1" "$RESULT_FIELD_DURATION_SECONDS" "$2"; }
result_tokens_set()            { result_set "$1" "$RESULT_FIELD_TOKENS" "$2"; }
result_tokens_per_second_set() { result_set "$1" "$RESULT_FIELD_TOKENS_PER_SECOND" "$2"; }
result_memory_mb_set()         { result_set "$1" "$RESULT_FIELD_MEMORY_MB" "$2"; }
result_cpu_percent_set()       { result_set "$1" "$RESULT_FIELD_CPU_PERCENT" "$2"; }
result_exit_code_set()         { result_set "$1" "$RESULT_FIELD_EXIT_CODE" "$2"; }
result_error_set()             { result_set "$1" "$RESULT_FIELD_ERROR" "$2"; }
result_output_set()            { result_set "$1" "$RESULT_FIELD_OUTPUT" "$2"; }

# ------------------------------------------------------------
# Result lifecycle helpers
# ------------------------------------------------------------

result_mark_running() {
    local id="$1"

    result_status_set "$id" "$RESULT_STATUS_RUNNING" || return $?
    result_timestamp_set "$id" "$(_result_now)"
}

result_mark_completed() {
    local id="$1"
    local exit_code="${2:-0}"

    result_status_set "$id" "$RESULT_STATUS_COMPLETED" || return $?
    result_exit_code_set "$id" "$exit_code" || return $?
    result_timestamp_set "$id" "$(_result_now)"
}

result_mark_failed() {
    local id="$1"
    local message="${2-}"
    local exit_code="${3:-1}"

    result_status_set "$id" "$RESULT_STATUS_FAILED" || return $?
    result_error_set "$id" "$message" || return $?
    result_exit_code_set "$id" "$exit_code" || return $?
    result_timestamp_set "$id" "$(_result_now)"
}

result_mark_skipped() {
    local id="$1"
    local reason="${2-}"

    result_status_set "$id" "$RESULT_STATUS_SKIPPED" || return $?
    result_error_set "$id" "$reason" || return $?
    result_timestamp_set "$id" "$(_result_now)"
}

result_mark_timeout() {
    local id="$1"
    local message="${2:-Benchmark execution timed out.}"

    result_status_set "$id" "$RESULT_STATUS_TIMEOUT" || return $?
    result_error_set "$id" "$message" || return $?
    result_timestamp_set "$id" "$(_result_now)"
}

result_mark_cancelled() {
    local id="$1"
    local reason="${2:-Benchmark execution was cancelled.}"

    result_status_set "$id" "$RESULT_STATUS_CANCELLED" || return $?
    result_error_set "$id" "$reason" || return $?
    result_timestamp_set "$id" "$(_result_now)"
}

# ------------------------------------------------------------
# Validation
# ------------------------------------------------------------

result_validate() {
    local id="$1"
    local index
    local field
    local value

    index="$(_result_index_of "$id")" || return 1

    _result_required_fields_present_by_index "$index" || return 1

    for field in "${RESULT_FIELD_ENUM[@]}"; do
        value="$(_result_get_by_index "$index" "$field")"

        if [ -n "$value" ] && ! _result_validate_field_value "$field" "$value"; then
            return 1
        fi
    done

    return 0
}

results_validate() {
    local id

    for id in "${RESULT_IDS[@]}"; do
        result_validate "$id" || return 1
    done

    return 0
}

# ------------------------------------------------------------
# Filtering helpers
# ------------------------------------------------------------

results_by_status() {
    local status="$1"
    local i=0

    result_status_valid "$status" || return "$EXIT_INVALID_ARGUMENT"

    while [ "$i" -lt "$RESULT_COUNT" ]; do
        if [ "${RESULT_STATUS_VALUES[$i]}" = "$status" ]; then
            printf "%s\n" "${RESULT_IDS[$i]}"
        fi
        i=$((i + 1))
    done
}

results_by_provider() {
    local provider="$1"
    local i=0

    provider_valid "$provider" || return "$EXIT_INVALID_ARGUMENT"

    while [ "$i" -lt "$RESULT_COUNT" ]; do
        if [ "${RESULT_PROVIDER_VALUES[$i]}" = "$provider" ]; then
            printf "%s\n" "${RESULT_IDS[$i]}"
        fi
        i=$((i + 1))
    done
}

results_by_model() {
    local model="$1"
    local i=0

    while [ "$i" -lt "$RESULT_COUNT" ]; do
        if [ "${RESULT_MODEL_VALUES[$i]}" = "$model" ]; then
            printf "%s\n" "${RESULT_IDS[$i]}"
        fi
        i=$((i + 1))
    done
}

results_by_workload() {
    local workload="$1"
    local i=0

    workload_valid "$workload" || return "$EXIT_INVALID_ARGUMENT"

    while [ "$i" -lt "$RESULT_COUNT" ]; do
        if [ "${RESULT_WORKLOAD_VALUES[$i]}" = "$workload" ]; then
            printf "%s\n" "${RESULT_IDS[$i]}"
        fi
        i=$((i + 1))
    done
}

results_by_profile() {
    local profile="$1"
    local i=0

    while [ "$i" -lt "$RESULT_COUNT" ]; do
        if [ "${RESULT_PROFILE_VALUES[$i]}" = "$profile" ]; then
            printf "%s\n" "${RESULT_IDS[$i]}"
        fi
        i=$((i + 1))
    done
}

# ------------------------------------------------------------
# Console presentation
# ------------------------------------------------------------

result_print() {
    local id="${1:-$RESULT_LAST_ID}"

    [ -n "$id" ] || return "$EXIT_FAILURE"
    result_exists "$id" || return "$EXIT_FAILURE"

    printf "Result ID          : %s\n" "$id"
    printf "Created            : %s\n" "$(result_created_get "$id")"
    printf "Timestamp          : %s\n" "$(result_timestamp_get "$id")"
    printf "Status             : %s\n" "$(result_status_get "$id")"
    printf "Provider           : %s\n" "$(result_provider_get "$id")"
    printf "Model              : %s\n" "$(result_model_get "$id")"
    printf "Profile            : %s\n" "$(result_profile_get "$id")"
    printf "Workload           : %s\n" "$(result_workload_get "$id")"

    local value

    value="$(result_duration_ms_get "$id")"
    [ -n "$value" ] && printf "Duration (ms)      : %s\n" "$value"

    value="$(result_duration_seconds_get "$id")"
    [ -n "$value" ] && printf "Duration (seconds) : %s\n" "$value"

    value="$(result_tokens_get "$id")"
    [ -n "$value" ] && printf "Tokens             : %s\n" "$value"

    value="$(result_tokens_per_second_get "$id")"
    [ -n "$value" ] && printf "Tokens / second    : %s\n" "$value"

    value="$(result_memory_mb_get "$id")"
    [ -n "$value" ] && printf "Memory (MB)        : %s\n" "$value"

    value="$(result_cpu_percent_get "$id")"
    [ -n "$value" ] && printf "CPU Percent        : %s\n" "$value"

    value="$(result_exit_code_get "$id")"
    [ -n "$value" ] && printf "Exit Code          : %s\n" "$value"

    value="$(result_error_get "$id")"
    [ -n "$value" ] && printf "Error              : %s\n" "$value"
}

results_print() {
    local id
    local first=1

    for id in "${RESULT_IDS[@]}"; do
        if [ "$first" -eq 0 ]; then
            printf "\n"
        fi
        first=0
        result_print "$id"
    done
}

# ------------------------------------------------------------
# JSON serialization
# ------------------------------------------------------------

result_json() {
    local id="${1:-$RESULT_LAST_ID}"

    [ -n "$id" ] || return "$EXIT_FAILURE"
    result_exists "$id" || return "$EXIT_FAILURE"

    printf '{'
    printf '"id":"%s",' "$(_result_json_escape "$(result_id_get "$id")")"
    printf '"created":"%s",' "$(_result_json_escape "$(result_created_get "$id")")"
    printf '"timestamp":"%s",' "$(_result_json_escape "$(result_timestamp_get "$id")")"
    printf '"status":"%s",' "$(_result_json_escape "$(result_status_get "$id")")"
    printf '"provider":"%s",' "$(_result_json_escape "$(result_provider_get "$id")")"
    printf '"model":"%s",' "$(_result_json_escape "$(result_model_get "$id")")"
    printf '"profile":"%s",' "$(_result_json_escape "$(result_profile_get "$id")")"
    printf '"workload":"%s",' "$(_result_json_escape "$(result_workload_get "$id")")"
    printf '"prompt":"%s",' "$(_result_json_escape "$(result_prompt_get "$id")")"

    local value

    value="$(result_duration_ms_get "$id")"
    if [ -n "$value" ]; then printf '"duration_ms":%s,' "$value"; else printf '"duration_ms":null,'; fi

    value="$(result_duration_seconds_get "$id")"
    if [ -n "$value" ]; then printf '"duration_seconds":%s,' "$value"; else printf '"duration_seconds":null,'; fi

    value="$(result_tokens_get "$id")"
    if [ -n "$value" ]; then printf '"tokens":%s,' "$value"; else printf '"tokens":null,'; fi

    value="$(result_tokens_per_second_get "$id")"
    if [ -n "$value" ]; then printf '"tokens_per_second":%s,' "$value"; else printf '"tokens_per_second":null,'; fi

    value="$(result_memory_mb_get "$id")"
    if [ -n "$value" ]; then printf '"memory_mb":%s,' "$value"; else printf '"memory_mb":null,'; fi

    value="$(result_cpu_percent_get "$id")"
    if [ -n "$value" ]; then printf '"cpu_percent":%s,' "$value"; else printf '"cpu_percent":null,'; fi

    value="$(result_exit_code_get "$id")"
    if [ -n "$value" ]; then printf '"exit_code":%s,' "$value"; else printf '"exit_code":null,'; fi

    printf '"error":"%s",' "$(_result_json_escape "$(result_error_get "$id")")"
    printf '"output":"%s"' "$(_result_json_escape "$(result_output_get "$id")")"
    printf '}'
}

results_json() {
    local i=0

    printf '['

    while [ "$i" -lt "$RESULT_COUNT" ]; do
        [ "$i" -gt 0 ] && printf ','
        result_json "${RESULT_IDS[$i]}"
        i=$((i + 1))
    done

    printf ']\n'
}

# ------------------------------------------------------------
# Markdown serialization
# ------------------------------------------------------------

result_markdown() {
    local id="${1:-$RESULT_LAST_ID}"

    [ -n "$id" ] || return "$EXIT_FAILURE"
    result_exists "$id" || return "$EXIT_FAILURE"

    cat <<EOF

## ${id}

| Field | Value |
|---|---|
| Created | $(_result_markdown_escape "$(result_created_get "$id")") |
| Timestamp | $(_result_markdown_escape "$(result_timestamp_get "$id")") |
| Status | $(_result_markdown_escape "$(result_status_get "$id")") |
| Provider | $(_result_markdown_escape "$(result_provider_get "$id")") |
| Model | $(_result_markdown_escape "$(result_model_get "$id")") |
| Profile | $(_result_markdown_escape "$(result_profile_get "$id")") |
| Workload | $(_result_markdown_escape "$(result_workload_get "$id")") |
| Duration (ms) | $(_result_markdown_escape "$(result_duration_ms_get "$id")") |
| Duration (seconds) | $(_result_markdown_escape "$(result_duration_seconds_get "$id")") |
| Tokens | $(_result_markdown_escape "$(result_tokens_get "$id")") |
| Tokens / second | $(_result_markdown_escape "$(result_tokens_per_second_get "$id")") |
| Memory (MB) | $(_result_markdown_escape "$(result_memory_mb_get "$id")") |
| CPU Percent | $(_result_markdown_escape "$(result_cpu_percent_get "$id")") |
| Exit Code | $(_result_markdown_escape "$(result_exit_code_get "$id")") |
| Error | $(_result_markdown_escape "$(result_error_get "$id")") |

### Prompt

$(_result_markdown_escape "$(result_prompt_get "$id")")

### Output

$(_result_markdown_escape "$(result_output_get "$id")")
EOF
}

results_markdown() {
    local id

    printf "# Benchmark Results\n\n"
    printf "Repository Version: %s\n\n" "$RESULT_REPOSITORY_RUNTIME_VERSION"
    printf "Result Count: %s\n" "$RESULT_COUNT"

    for id in "${RESULT_IDS[@]}"; do
        result_markdown "$id"
    done
}

# ------------------------------------------------------------
# CSV serialization
# ------------------------------------------------------------

results_csv_header() {
    printf '%s\n' \
        'id,created,timestamp,status,provider,model,profile,workload,prompt,duration_ms,duration_seconds,tokens,tokens_per_second,memory_mb,cpu_percent,exit_code,error,output'
}

result_csv() {
    local id="${1:-$RESULT_LAST_ID}"

    [ -n "$id" ] || return "$EXIT_FAILURE"
    result_exists "$id" || return "$EXIT_FAILURE"

    _result_csv_escape "$(result_id_get "$id")"; printf ','
    _result_csv_escape "$(result_created_get "$id")"; printf ','
    _result_csv_escape "$(result_timestamp_get "$id")"; printf ','
    _result_csv_escape "$(result_status_get "$id")"; printf ','
    _result_csv_escape "$(result_provider_get "$id")"; printf ','
    _result_csv_escape "$(result_model_get "$id")"; printf ','
    _result_csv_escape "$(result_profile_get "$id")"; printf ','
    _result_csv_escape "$(result_workload_get "$id")"; printf ','
    _result_csv_escape "$(result_prompt_get "$id")"; printf ','
    _result_csv_escape "$(result_duration_ms_get "$id")"; printf ','
    _result_csv_escape "$(result_duration_seconds_get "$id")"; printf ','
    _result_csv_escape "$(result_tokens_get "$id")"; printf ','
    _result_csv_escape "$(result_tokens_per_second_get "$id")"; printf ','
    _result_csv_escape "$(result_memory_mb_get "$id")"; printf ','
    _result_csv_escape "$(result_cpu_percent_get "$id")"; printf ','
    _result_csv_escape "$(result_exit_code_get "$id")"; printf ','
    _result_csv_escape "$(result_error_get "$id")"; printf ','
    _result_csv_escape "$(result_output_get "$id")"
    printf '\n'
}

results_csv() {
    local id

    results_csv_header

    for id in "${RESULT_IDS[@]}"; do
        result_csv "$id"
    done
}

# ------------------------------------------------------------
# Text serialization
# ------------------------------------------------------------

result_text() {
    result_print "${1:-$RESULT_LAST_ID}"
}

results_text() {
    results_print
}

# ------------------------------------------------------------
# Persistence helpers
#
# Export is supported directly. Import is intentionally omitted
# until a dedicated parser and schema migration strategy are
# implemented.
# ------------------------------------------------------------

results_save_json() {
    local file="$1"

    [ -n "$file" ] || return "$EXIT_INVALID_ARGUMENT"

    if ! results_json > "$file"; then
        _result_serialization_error \
            "results_save_json" \
            "Failed to write Result Repository as JSON." \
            "Destination: ${file}"
        return "$EXIT_SERIALIZATION_FAILED"
    fi

    return "$EXIT_SUCCESS"
}

results_save_markdown() {
    local file="$1"

    [ -n "$file" ] || return "$EXIT_INVALID_ARGUMENT"

    if ! results_markdown > "$file"; then
        _result_serialization_error \
            "results_save_markdown" \
            "Failed to write Result Repository as Markdown." \
            "Destination: ${file}"
        return "$EXIT_SERIALIZATION_FAILED"
    fi

    return "$EXIT_SUCCESS"
}

results_save_csv() {
    local file="$1"

    [ -n "$file" ] || return "$EXIT_INVALID_ARGUMENT"

    if ! results_csv > "$file"; then
        _result_serialization_error \
            "results_save_csv" \
            "Failed to write Result Repository as CSV." \
            "Destination: ${file}"
        return "$EXIT_SERIALIZATION_FAILED"
    fi

    return "$EXIT_SUCCESS"
}

results_save_text() {
    local file="$1"

    [ -n "$file" ] || return "$EXIT_INVALID_ARGUMENT"

    if ! results_text > "$file"; then
        _result_serialization_error \
            "results_save_text" \
            "Failed to write Result Repository as text." \
            "Destination: ${file}"
        return "$EXIT_SERIALIZATION_FAILED"
    fi

    return "$EXIT_SUCCESS"
}

# ------------------------------------------------------------
# Diagnostics
# ------------------------------------------------------------

results_repository_version() {
    printf "%s\n" "$RESULT_REPOSITORY_RUNTIME_VERSION"
}

results_diagnostics() {
    printf "Repository Version : %s\n" "$RESULT_REPOSITORY_RUNTIME_VERSION"
    printf "Schema Version     : %s\n" "$BENCHMARK_SCHEMA_VERSION"
    printf "Result Count       : %s\n" "$RESULT_COUNT"
    printf "Sequence           : %s\n" "$RESULT_SEQUENCE"
    printf "Last Result ID     : %s\n" "${RESULT_LAST_ID:-none}"

    if results_validate; then
        printf "Repository Valid   : yes\n"
        return "$EXIT_SUCCESS"
    fi

    printf "Repository Valid   : no\n"
    return "$EXIT_FAILURE"
}
