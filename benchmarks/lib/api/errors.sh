#!/usr/bin/env bash
#
# ============================================================
# Personal AI Platform
# Benchmark Framework
#
# File: errors.sh
#
# Purpose:
#   Implements the Error Framework and Error Repository.
#
# Responsibilities:
#   - Structured error creation
#   - Error repository lifecycle
#   - Object identity
#   - CRUD-style repository operations
#   - Last-error tracking
#   - Validation integration
#   - Text, JSON, and Markdown serialization
#
# Design:
#   - Conforms to ADR-0008 (Standardized Error Framework)
#   - Conforms to ADR-0009 (Standardized Repository Pattern)
#   - Uses Bash 3.2-compatible indexed arrays for macOS
#   - Delegates schema and enum definitions to definitions.sh
#   - Delegates business validation to validators.sh
#
# Version: 1.0.0
#
# Notes:
#   Bash function return values are limited to 0-255. Framework
#   error codes such as ERR_INVALID_PROVIDER=1001 are stored as
#   structured error data, while functions return standard shell
#   status codes or framework exit codes that fit within 0-255.
# ============================================================

[[ -n "${BENCHMARK_ERRORS_LOADED:-}" ]] && return 0
BENCHMARK_ERRORS_LOADED=1

# ------------------------------------------------------------
# Dependency discovery
# ------------------------------------------------------------

ERRORS_API_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ERRORS_LIB_DIR="$(cd "${ERRORS_API_DIR}/.." && pwd)"
ERRORS_CORE_DIR="${ERRORS_LIB_DIR}/core"

# shellcheck source=/dev/null
source "${ERRORS_CORE_DIR}/definitions.sh"

# shellcheck source=/dev/null
source "${ERRORS_CORE_DIR}/validators.sh"

# ------------------------------------------------------------
# Compatibility defaults
# ------------------------------------------------------------

: "${EXIT_SUCCESS:=0}"
: "${EXIT_FAILURE:=1}"
: "${EXIT_INVALID_ARGUMENT:=2}"
: "${EXIT_INVALID_STATE:=3}"

: "${ERROR_CATEGORY_INTERNAL:=internal}"
: "${ERROR_CATEGORY_VALIDATION:=validation}"

: "${ERROR_SEVERITY_INFO:=info}"
: "${ERROR_SEVERITY_WARNING:=warning}"
: "${ERROR_SEVERITY_ERROR:=error}"
: "${ERROR_SEVERITY_FATAL:=fatal}"

: "${ERR_INTERNAL:=9000}"
: "${ERR_INVALID_ARGUMENT:=1000}"

# ------------------------------------------------------------
# Repository metadata
# ------------------------------------------------------------

readonly ERROR_REPOSITORY_VERSION="1.0"
readonly ERROR_ID_PREFIX="error"
readonly ERROR_ID_PADDING=6
readonly ERROR_TIMESTAMP_FORMAT="%Y-%m-%dT%H:%M:%SZ"

# ------------------------------------------------------------
# Repository storage
#
# Bash 3.2 does not support associative arrays. The repository
# therefore uses parallel indexed arrays, one slot per object.
# ERROR_IDS is the canonical object index.
# ------------------------------------------------------------

ERROR_IDS=()
ERROR_TIMESTAMPS=()
ERROR_COMPONENTS=()
ERROR_FUNCTIONS=()
ERROR_CODES=()
ERROR_EXIT_CODES=()
ERROR_CATEGORIES=()
ERROR_SEVERITIES=()
ERROR_MESSAGES=()
ERROR_DETAILS=()
ERROR_SUGGESTIONS=()

ERROR_COUNT=0
ERROR_SEQUENCE=0
ERROR_LAST_ID=""
ERROR_GENERATED_ID=""

# ------------------------------------------------------------
# Internal helpers
# ------------------------------------------------------------

_error_now() {
    date -u +"${ERROR_TIMESTAMP_FORMAT}"
}

_error_generate_id() {
    ERROR_SEQUENCE=$((ERROR_SEQUENCE + 1))
    ERROR_GENERATED_ID="$(
        printf "%s-%0*d" \
            "${ERROR_ID_PREFIX}" \
            "${ERROR_ID_PADDING}" \
            "${ERROR_SEQUENCE}"
    )"
}

_error_index_of() {
    local id="$1"
    local i=0

    while [ "$i" -lt "${#ERROR_IDS[@]}" ]; do
        if [ "${ERROR_IDS[$i]}" = "$id" ]; then
            printf "%s\n" "$i"
            return 0
        fi
        i=$((i + 1))
    done

    return 1
}

_error_field_supported() {
    local field="$1"
    local candidate

    for candidate in "${ERROR_FIELD_ENUM[@]}"; do
        [ "$candidate" = "$field" ] && return 0
    done

    return 1
}

_error_category_valid() {
    local value="$1"
    local candidate

    for candidate in "${ERROR_CATEGORY_ENUM[@]}"; do
        [ "$candidate" = "$value" ] && return 0
    done

    return 1
}

_error_severity_valid() {
    local value="$1"
    local candidate

    for candidate in "${ERROR_SEVERITY_ENUM[@]}"; do
        [ "$candidate" = "$value" ] && return 0
    done

    return 1
}

_error_json_escape() {
    # JSON string escaping without jq dependency.
    # Reads one argument and emits escaped text without surrounding quotes.
    local value="${1-}"

    value=${value//\\/\\\\}
    value=${value//\"/\\\"}
    value=${value//$'\n'/\\n}
    value=${value//$'\r'/\\r}
    value=${value//$'\t'/\\t}

    printf "%s" "$value"
}

_error_markdown_escape() {
    local value="${1-}"

    # Keep Markdown serialization readable while preventing table breaks.
    value=${value//$'\r'/}
    value=${value//$'\n'/<br>}
    value=${value//|/\\|}

    printf "%s" "$value"
}

_error_shift_left_from() {
    local start="$1"
    local i="$start"
    local last_index=$((ERROR_COUNT - 1))

    while [ "$i" -lt "$last_index" ]; do
        ERROR_IDS[$i]="${ERROR_IDS[$((i + 1))]}"
        ERROR_TIMESTAMPS[$i]="${ERROR_TIMESTAMPS[$((i + 1))]}"
        ERROR_COMPONENTS[$i]="${ERROR_COMPONENTS[$((i + 1))]}"
        ERROR_FUNCTIONS[$i]="${ERROR_FUNCTIONS[$((i + 1))]}"
        ERROR_CODES[$i]="${ERROR_CODES[$((i + 1))]}"
        ERROR_EXIT_CODES[$i]="${ERROR_EXIT_CODES[$((i + 1))]}"
        ERROR_CATEGORIES[$i]="${ERROR_CATEGORIES[$((i + 1))]}"
        ERROR_SEVERITIES[$i]="${ERROR_SEVERITIES[$((i + 1))]}"
        ERROR_MESSAGES[$i]="${ERROR_MESSAGES[$((i + 1))]}"
        ERROR_DETAILS[$i]="${ERROR_DETAILS[$((i + 1))]}"
        ERROR_SUGGESTIONS[$i]="${ERROR_SUGGESTIONS[$((i + 1))]}"

        i=$((i + 1))
    done

    unset 'ERROR_IDS[$last_index]'
    unset 'ERROR_TIMESTAMPS[$last_index]'
    unset 'ERROR_COMPONENTS[$last_index]'
    unset 'ERROR_FUNCTIONS[$last_index]'
    unset 'ERROR_CODES[$last_index]'
    unset 'ERROR_EXIT_CODES[$last_index]'
    unset 'ERROR_CATEGORIES[$last_index]'
    unset 'ERROR_SEVERITIES[$last_index]'
    unset 'ERROR_MESSAGES[$last_index]'
    unset 'ERROR_DETAILS[$last_index]'
    unset 'ERROR_SUGGESTIONS[$last_index]'
}

_error_set_by_index() {
    local index="$1"
    local field="$2"
    local value="${3-}"

    case "$field" in
        "$ERROR_FIELD_TIMESTAMP")  ERROR_TIMESTAMPS[$index]="$value" ;;
        "$ERROR_FIELD_COMPONENT")  ERROR_COMPONENTS[$index]="$value" ;;
        "$ERROR_FIELD_FUNCTION")   ERROR_FUNCTIONS[$index]="$value" ;;
        "$ERROR_FIELD_CODE")       ERROR_CODES[$index]="$value" ;;
        "$ERROR_FIELD_EXIT_CODE")  ERROR_EXIT_CODES[$index]="$value" ;;
        "$ERROR_FIELD_CATEGORY")   ERROR_CATEGORIES[$index]="$value" ;;
        "$ERROR_FIELD_SEVERITY")   ERROR_SEVERITIES[$index]="$value" ;;
        "$ERROR_FIELD_MESSAGE")    ERROR_MESSAGES[$index]="$value" ;;
        "$ERROR_FIELD_DETAILS")    ERROR_DETAILS[$index]="$value" ;;
        "$ERROR_FIELD_SUGGESTION") ERROR_SUGGESTIONS[$index]="$value" ;;
        *)
            return "$EXIT_INVALID_ARGUMENT"
            ;;
    esac

    return "$EXIT_SUCCESS"
}

_error_get_by_index() {
    local index="$1"
    local field="$2"

    case "$field" in
        "$ERROR_FIELD_TIMESTAMP")  printf "%s\n" "${ERROR_TIMESTAMPS[$index]-}" ;;
        "$ERROR_FIELD_COMPONENT")  printf "%s\n" "${ERROR_COMPONENTS[$index]-}" ;;
        "$ERROR_FIELD_FUNCTION")   printf "%s\n" "${ERROR_FUNCTIONS[$index]-}" ;;
        "$ERROR_FIELD_CODE")       printf "%s\n" "${ERROR_CODES[$index]-}" ;;
        "$ERROR_FIELD_EXIT_CODE")  printf "%s\n" "${ERROR_EXIT_CODES[$index]-}" ;;
        "$ERROR_FIELD_CATEGORY")   printf "%s\n" "${ERROR_CATEGORIES[$index]-}" ;;
        "$ERROR_FIELD_SEVERITY")   printf "%s\n" "${ERROR_SEVERITIES[$index]-}" ;;
        "$ERROR_FIELD_MESSAGE")    printf "%s\n" "${ERROR_MESSAGES[$index]-}" ;;
        "$ERROR_FIELD_DETAILS")    printf "%s\n" "${ERROR_DETAILS[$index]-}" ;;
        "$ERROR_FIELD_SUGGESTION") printf "%s\n" "${ERROR_SUGGESTIONS[$index]-}" ;;
        *)
            return "$EXIT_INVALID_ARGUMENT"
            ;;
    esac

    return "$EXIT_SUCCESS"
}

_error_validate_create_args() {
    local component="$1"
    local function_name="$2"
    local code="$3"
    local exit_code="$4"
    local category="$5"
    local severity="$6"
    local message="$7"

    [ -n "$component" ] || return 1
    [ -n "$function_name" ] || return 1
    [ -n "$code" ] || return 1
    [ -n "$message" ] || return 1

    is_integer "$code" || return 1
    is_integer "$exit_code" || return 1

    _error_category_valid "$category" || return 1
    _error_severity_valid "$severity" || return 1

    return 0
}

# ------------------------------------------------------------
# Repository predicates
# ------------------------------------------------------------

errors_empty() {
    [ "$ERROR_COUNT" -eq 0 ]
}

errors_exists() {
    local id="$1"
    _error_index_of "$id" >/dev/null 2>&1
}

error_exists() {
    errors_exists "$1"
}

# ------------------------------------------------------------
# Repository queries
# ------------------------------------------------------------

errors_count() {
    printf "%s\n" "$ERROR_COUNT"
}

errors_ids() {
    [ "$ERROR_COUNT" -gt 0 ] || return 0
    printf "%s\n" "${ERROR_IDS[@]}"
}

error_last() {
    [ -n "$ERROR_LAST_ID" ] || return 1
    printf "%s\n" "$ERROR_LAST_ID"
}

error_first() {
    [ "$ERROR_COUNT" -gt 0 ] || return 1
    printf "%s\n" "${ERROR_IDS[0]}"
}

# ------------------------------------------------------------
# Repository lifecycle
# ------------------------------------------------------------

errors_clear_all() {
    ERROR_IDS=()
    ERROR_TIMESTAMPS=()
    ERROR_COMPONENTS=()
    ERROR_FUNCTIONS=()
    ERROR_CODES=()
    ERROR_EXIT_CODES=()
    ERROR_CATEGORIES=()
    ERROR_SEVERITIES=()
    ERROR_MESSAGES=()
    ERROR_DETAILS=()
    ERROR_SUGGESTIONS=()

    ERROR_COUNT=0
    ERROR_LAST_ID=""

    return "$EXIT_SUCCESS"
}

errors_reset() {
    errors_clear_all
    ERROR_SEQUENCE=0
    ERROR_GENERATED_ID=""
    return "$EXIT_SUCCESS"
}

# ------------------------------------------------------------
# Object lifecycle
# ------------------------------------------------------------

error_create() {
    local component="$1"
    local function_name="$2"
    local code="$3"
    local exit_code="$4"
    local category="$5"
    local severity="$6"
    local message="$7"
    local details="${8-}"
    local suggestion="${9-}"

    if ! _error_validate_create_args \
        "$component" \
        "$function_name" \
        "$code" \
        "$exit_code" \
        "$category" \
        "$severity" \
        "$message"
    then
        return "$EXIT_INVALID_ARGUMENT"
    fi

    local id
    local index

    _error_generate_id
    id="$ERROR_GENERATED_ID"
    index="$ERROR_COUNT"

    ERROR_IDS[$index]="$id"
    ERROR_TIMESTAMPS[$index]="$(_error_now)"
    ERROR_COMPONENTS[$index]="$component"
    ERROR_FUNCTIONS[$index]="$function_name"
    ERROR_CODES[$index]="$code"
    ERROR_EXIT_CODES[$index]="$exit_code"
    ERROR_CATEGORIES[$index]="$category"
    ERROR_SEVERITIES[$index]="$severity"
    ERROR_MESSAGES[$index]="$message"
    ERROR_DETAILS[$index]="$details"
    ERROR_SUGGESTIONS[$index]="$suggestion"

    ERROR_COUNT=$((ERROR_COUNT + 1))
    ERROR_LAST_ID="$id"

    printf "%s\n" "$id"
    return "$EXIT_SUCCESS"
}

error_delete() {
    local id="$1"
    local index

    index="$(_error_index_of "$id")" || return "$EXIT_FAILURE"

    _error_shift_left_from "$index"

    ERROR_COUNT=$((ERROR_COUNT - 1))

    if [ "$ERROR_COUNT" -eq 0 ]; then
        ERROR_LAST_ID=""
    else
        ERROR_LAST_ID="${ERROR_IDS[$((ERROR_COUNT - 1))]}"
    fi

    return "$EXIT_SUCCESS"
}

error_clear() {
    error_delete "$1"
}

# ------------------------------------------------------------
# Object field access
# ------------------------------------------------------------

error_get() {
    local id="$1"
    local field="$2"
    local index

    _error_field_supported "$field" || return "$EXIT_INVALID_ARGUMENT"
    index="$(_error_index_of "$id")" || return "$EXIT_FAILURE"

    _error_get_by_index "$index" "$field"
}

error_set() {
    local id="$1"
    local field="$2"
    local value="${3-}"
    local index

    _error_field_supported "$field" || return "$EXIT_INVALID_ARGUMENT"
    index="$(_error_index_of "$id")" || return "$EXIT_FAILURE"

    case "$field" in
        "$ERROR_FIELD_CATEGORY")
            _error_category_valid "$value" || return "$EXIT_INVALID_ARGUMENT"
            ;;
        "$ERROR_FIELD_SEVERITY")
            _error_severity_valid "$value" || return "$EXIT_INVALID_ARGUMENT"
            ;;
        "$ERROR_FIELD_CODE"|"$ERROR_FIELD_EXIT_CODE")
            is_integer "$value" || return "$EXIT_INVALID_ARGUMENT"
            ;;
    esac

    _error_set_by_index "$index" "$field" "$value"
}

# ------------------------------------------------------------
# Typed getters
# ------------------------------------------------------------

error_timestamp_get()  { error_get "$1" "$ERROR_FIELD_TIMESTAMP"; }
error_component_get()  { error_get "$1" "$ERROR_FIELD_COMPONENT"; }
error_function_get()   { error_get "$1" "$ERROR_FIELD_FUNCTION"; }
error_code_get()       { error_get "$1" "$ERROR_FIELD_CODE"; }
error_exit_code_get()  { error_get "$1" "$ERROR_FIELD_EXIT_CODE"; }
error_category_get()   { error_get "$1" "$ERROR_FIELD_CATEGORY"; }
error_severity_get()   { error_get "$1" "$ERROR_FIELD_SEVERITY"; }
error_message_get()    { error_get "$1" "$ERROR_FIELD_MESSAGE"; }
error_details_get()    { error_get "$1" "$ERROR_FIELD_DETAILS"; }
error_suggestion_get() { error_get "$1" "$ERROR_FIELD_SUGGESTION"; }

# ------------------------------------------------------------
# Typed setters
# ------------------------------------------------------------

error_timestamp_set()  { error_set "$1" "$ERROR_FIELD_TIMESTAMP" "$2"; }
error_component_set()  { error_set "$1" "$ERROR_FIELD_COMPONENT" "$2"; }
error_function_set()   { error_set "$1" "$ERROR_FIELD_FUNCTION" "$2"; }
error_code_set()       { error_set "$1" "$ERROR_FIELD_CODE" "$2"; }
error_exit_code_set()  { error_set "$1" "$ERROR_FIELD_EXIT_CODE" "$2"; }
error_category_set()   { error_set "$1" "$ERROR_FIELD_CATEGORY" "$2"; }
error_severity_set()   { error_set "$1" "$ERROR_FIELD_SEVERITY" "$2"; }
error_message_set()    { error_set "$1" "$ERROR_FIELD_MESSAGE" "$2"; }
error_details_set()    { error_set "$1" "$ERROR_FIELD_DETAILS" "$2"; }
error_suggestion_set() { error_set "$1" "$ERROR_FIELD_SUGGESTION" "$2"; }

# ------------------------------------------------------------
# Validation
# ------------------------------------------------------------

error_validate() {
    local id="$1"

    error_exists "$id" || return 1

    local component
    local function_name
    local code
    local exit_code
    local category
    local severity
    local message

    component="$(error_component_get "$id")"
    function_name="$(error_function_get "$id")"
    code="$(error_code_get "$id")"
    exit_code="$(error_exit_code_get "$id")"
    category="$(error_category_get "$id")"
    severity="$(error_severity_get "$id")"
    message="$(error_message_get "$id")"

    _error_validate_create_args \
        "$component" \
        "$function_name" \
        "$code" \
        "$exit_code" \
        "$category" \
        "$severity" \
        "$message"
}

errors_validate() {
    local id

    for id in "${ERROR_IDS[@]}"; do
        error_validate "$id" || return 1
    done

    return 0
}

# ------------------------------------------------------------
# Filtering helpers
# ------------------------------------------------------------

errors_by_category() {
    local category="$1"
    local i=0

    _error_category_valid "$category" || return "$EXIT_INVALID_ARGUMENT"

    while [ "$i" -lt "$ERROR_COUNT" ]; do
        if [ "${ERROR_CATEGORIES[$i]}" = "$category" ]; then
            printf "%s\n" "${ERROR_IDS[$i]}"
        fi
        i=$((i + 1))
    done
}

errors_by_severity() {
    local severity="$1"
    local i=0

    _error_severity_valid "$severity" || return "$EXIT_INVALID_ARGUMENT"

    while [ "$i" -lt "$ERROR_COUNT" ]; do
        if [ "${ERROR_SEVERITIES[$i]}" = "$severity" ]; then
            printf "%s\n" "${ERROR_IDS[$i]}"
        fi
        i=$((i + 1))
    done
}

# ------------------------------------------------------------
# Console presentation
# ------------------------------------------------------------

error_print() {
    local id="${1:-$ERROR_LAST_ID}"

    [ -n "$id" ] || return "$EXIT_FAILURE"
    error_exists "$id" || return "$EXIT_FAILURE"

    printf "Error ID   : %s\n" "$id"
    printf "Timestamp  : %s\n" "$(error_timestamp_get "$id")"
    printf "Component  : %s\n" "$(error_component_get "$id")"
    printf "Function   : %s\n" "$(error_function_get "$id")"
    printf "Code       : %s\n" "$(error_code_get "$id")"
    printf "Exit Code  : %s\n" "$(error_exit_code_get "$id")"
    printf "Category   : %s\n" "$(error_category_get "$id")"
    printf "Severity   : %s\n" "$(error_severity_get "$id")"
    printf "Message    : %s\n" "$(error_message_get "$id")"

    local details
    local suggestion

    details="$(error_details_get "$id")"
    suggestion="$(error_suggestion_get "$id")"

    [ -n "$details" ] && printf "Details    : %s\n" "$details"
    [ -n "$suggestion" ] && printf "Suggestion : %s\n" "$suggestion"
}

errors_print() {
    local id
    local first=1

    for id in "${ERROR_IDS[@]}"; do
        if [ "$first" -eq 0 ]; then
            printf "\n"
        fi
        first=0

        error_print "$id"
    done
}

# ------------------------------------------------------------
# JSON serialization
# ------------------------------------------------------------

error_json() {
    local id="${1:-$ERROR_LAST_ID}"

    [ -n "$id" ] || return "$EXIT_FAILURE"
    error_exists "$id" || return "$EXIT_FAILURE"

    printf '{'
    printf '"id":"%s",' "$(_error_json_escape "$id")"
    printf '"timestamp":"%s",' "$(_error_json_escape "$(error_timestamp_get "$id")")"
    printf '"component":"%s",' "$(_error_json_escape "$(error_component_get "$id")")"
    printf '"function":"%s",' "$(_error_json_escape "$(error_function_get "$id")")"
    printf '"code":%s,' "$(error_code_get "$id")"
    printf '"exit_code":%s,' "$(error_exit_code_get "$id")"
    printf '"category":"%s",' "$(_error_json_escape "$(error_category_get "$id")")"
    printf '"severity":"%s",' "$(_error_json_escape "$(error_severity_get "$id")")"
    printf '"message":"%s",' "$(_error_json_escape "$(error_message_get "$id")")"
    printf '"details":"%s",' "$(_error_json_escape "$(error_details_get "$id")")"
    printf '"suggestion":"%s"' "$(_error_json_escape "$(error_suggestion_get "$id")")"
    printf '}'
}

errors_json() {
    local i=0

    printf '['

    while [ "$i" -lt "$ERROR_COUNT" ]; do
        [ "$i" -gt 0 ] && printf ','
        error_json "${ERROR_IDS[$i]}"
        i=$((i + 1))
    done

    printf ']\n'
}

# ------------------------------------------------------------
# Markdown serialization
# ------------------------------------------------------------

error_markdown() {
    local id="${1:-$ERROR_LAST_ID}"

    [ -n "$id" ] || return "$EXIT_FAILURE"
    error_exists "$id" || return "$EXIT_FAILURE"

    local details
    local suggestion

    details="$(_error_markdown_escape "$(error_details_get "$id")")"
    suggestion="$(_error_markdown_escape "$(error_suggestion_get "$id")")"

    cat <<EOF

## ${id}

| Field | Value |
|---|---|
| Timestamp | $(_error_markdown_escape "$(error_timestamp_get "$id")") |
| Component | $(_error_markdown_escape "$(error_component_get "$id")") |
| Function | $(_error_markdown_escape "$(error_function_get "$id")") |
| Code | $(error_code_get "$id") |
| Exit Code | $(error_exit_code_get "$id") |
| Category | $(_error_markdown_escape "$(error_category_get "$id")") |
| Severity | $(_error_markdown_escape "$(error_severity_get "$id")") |
| Message | $(_error_markdown_escape "$(error_message_get "$id")") |
| Details | ${details} |
| Suggestion | ${suggestion} |
EOF
}

errors_markdown() {
    local id

    printf "# Error Repository\n\n"
    printf "Repository Version: %s\n\n" "$ERROR_REPOSITORY_VERSION"
    printf "Error Count: %s\n" "$ERROR_COUNT"

    for id in "${ERROR_IDS[@]}"; do
        error_markdown "$id"
    done
}

# ------------------------------------------------------------
# Text serialization
# ------------------------------------------------------------

error_text() {
    error_print "${1:-$ERROR_LAST_ID}"
}

errors_text() {
    errors_print
}

# ------------------------------------------------------------
# Persistence helpers
#
# These export the current repository. Import is intentionally
# not implemented here because safe import requires a parser and
# stronger schema/version handling. That can be added later
# without changing the public repository API.
# ------------------------------------------------------------

errors_save_json() {
    local file="$1"

    [ -n "$file" ] || return "$EXIT_INVALID_ARGUMENT"

    if ! errors_json > "$file"; then
        return "$EXIT_FAILURE"
    fi

    return "$EXIT_SUCCESS"
}

errors_save_markdown() {
    local file="$1"

    [ -n "$file" ] || return "$EXIT_INVALID_ARGUMENT"

    if ! errors_markdown > "$file"; then
        return "$EXIT_FAILURE"
    fi

    return "$EXIT_SUCCESS"
}

errors_save_text() {
    local file="$1"

    [ -n "$file" ] || return "$EXIT_INVALID_ARGUMENT"

    if ! errors_text > "$file"; then
        return "$EXIT_FAILURE"
    fi

    return "$EXIT_SUCCESS"
}

# ------------------------------------------------------------
# Diagnostics
# ------------------------------------------------------------

errors_repository_version() {
    printf "%s\n" "$ERROR_REPOSITORY_VERSION"
}

errors_diagnostics() {
    printf "Repository Version : %s\n" "$ERROR_REPOSITORY_VERSION"
    printf "Error Count        : %s\n" "$ERROR_COUNT"
    printf "Sequence           : %s\n" "$ERROR_SEQUENCE"
    printf "Last Error ID      : %s\n" "${ERROR_LAST_ID:-none}"

    if errors_validate; then
        printf "Repository Valid   : yes\n"
        return "$EXIT_SUCCESS"
    fi

    printf "Repository Valid   : no\n"
    return "$EXIT_FAILURE"
}
