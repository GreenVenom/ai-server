#!/usr/bin/env bash
#
# ============================================================
# Personal AI Platform
# Benchmark Framework
#
# File: validators.sh
#
# Purpose:
#   Provides framework-level validation rules.
#
# Responsibilities:
#   - Enum membership validation
#   - Result schema validation
#   - Result field type validation
#
# Compatibility:
#   - Bash 3.2+
#   - Safe under set -u
# ============================================================

[[ -n "${BENCHMARK_VALIDATORS_LOADED:-}" ]] && return 0
BENCHMARK_VALIDATORS_LOADED=1

VALIDATORS_CORE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=/dev/null
source "${VALIDATORS_CORE_DIR}/definitions.sh"

# shellcheck source=/dev/null
source "${VALIDATORS_CORE_DIR}/types.sh"

# ------------------------------------------------------------
# Generic helpers
# ------------------------------------------------------------

array_contains() {
    local needle="$1"
    shift

    local item
    for item in "$@"; do
        [ "$item" = "$needle" ] && return 0
    done

    return 1
}

# ------------------------------------------------------------
# Enum predicates
# ------------------------------------------------------------

provider_valid() {
    array_contains "$1" "${PROVIDER_ENUM[@]}"
}

capability_valid() {
    array_contains "$1" "${CAPABILITY_ENUM[@]}"
}

workload_valid() {
    array_contains "$1" "${WORKLOAD_ENUM[@]}"
}

result_status_valid() {
    array_contains "$1" "${RESULT_STATUS_ENUM[@]}"
}

output_format_valid() {
    array_contains "$1" "${OUTPUT_FORMAT_ENUM[@]}"
}

error_category_valid() {
    array_contains "$1" "${ERROR_CATEGORY_ENUM[@]}"
}

error_severity_valid() {
    array_contains "$1" "${ERROR_SEVERITY_ENUM[@]}"
}

result_field_valid() {
    array_contains "$1" "${RESULT_FIELD_ENUM[@]}"
}

error_field_valid() {
    array_contains "$1" "${ERROR_FIELD_ENUM[@]}"
}

# ------------------------------------------------------------
# Result schema helpers
# ------------------------------------------------------------

result_field_type() {
    result_field_type_lookup "$1"
}

result_field_required() {
    local required

    required="$(result_field_required_lookup "$1")" || return 1
    [ "$required" = "true" ]
}

# ------------------------------------------------------------
# Result value validation
# ------------------------------------------------------------

result_value_valid() {
    local field="$1"
    local value="${2-}"
    local type

    result_field_valid "$field" || return 1

    type="$(result_field_type "$field")" || return 1

    case "$field" in
        "$RESULT_FIELD_STATUS")
            result_status_valid "$value"
            ;;
        "$RESULT_FIELD_PROVIDER")
            provider_valid "$value"
            ;;
        "$RESULT_FIELD_WORKLOAD")
            [ -z "$value" ] || workload_valid "$value"
            ;;
        *)
            validate_type "$type" "$value"
            ;;
    esac
}

# ------------------------------------------------------------
# Assertions
#
# These are intentionally side-effect free. They return success
# or failure and do not print or create Error Repository objects.
# ------------------------------------------------------------

assert_provider() {
    provider_valid "$1"
}

assert_capability() {
    capability_valid "$1"
}

assert_workload() {
    workload_valid "$1"
}

assert_result_field() {
    result_field_valid "$1"
}

assert_result_value() {
    result_value_valid "$1" "${2-}"
}

assert_result_status() {
    result_status_valid "$1"
}

assert_output_format() {
    output_format_valid "$1"
}

assert_error_category() {
    error_category_valid "$1"
}

assert_error_severity() {
    error_severity_valid "$1"
}

# ------------------------------------------------------------
# Required-field validation
#
# The getter function must accept:
#   getter <field>
#
# and print the field value.
# ------------------------------------------------------------

result_required_fields_present() {
    local getter="$1"
    local field
    local value

    for field in "${RESULT_FIELD_ENUM[@]}"; do
        if result_field_required "$field"; then
            value="$("$getter" "$field")"
            [ -n "$value" ] || return 1
        fi
    done

    return 0
}
