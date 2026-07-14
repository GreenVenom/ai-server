#!/usr/bin/env bash
#
# ============================================================
# Personal AI Platform
# Benchmark Framework
#
# File: validators.sh
#
# Purpose:
#   Framework validation library.
#
# Responsibilities:
#
#   • Validate framework objects
#   • Validate providers
#   • Validate workloads
#   • Validate result schema
#   • Validate output formats
#   • Provide assertion helpers
#
# This library builds upon:
#
#   definitions.sh
#   types.sh
#
# ============================================================

[[ -n "${BENCHMARK_VALIDATORS_LOADED:-}" ]] && return
readonly BENCHMARK_VALIDATORS_LOADED=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${SCRIPT_DIR}/definitions.sh"
source "${SCRIPT_DIR}/types.sh"

############################################################
# Generic Helpers
############################################################

array_contains() {

    local value="$1"
    shift

    local item

    for item in "$@"
    do
        [[ "$item" == "$value" ]] && return 0
    done

    return 1

}

############################################################
# Enumerations
############################################################

provider_valid() {

    array_contains "$1" "${PROVIDER_ENUM[@]}"

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

result_field_valid() {

    array_contains "$1" "${RESULT_FIELD_ENUM[@]}"

}

############################################################
# Result Schema
############################################################

result_field_type() {

    local field="$1"

    echo "${RESULT_FIELD_TYPES[$field]}"

}

result_field_required() {

    [[ "${RESULT_FIELD_REQUIRED[$1]}" == "true" ]]

}

############################################################
# Value Validation
############################################################

result_value_valid() {

    local field="$1"

    local value="$2"

    result_field_valid "$field" || return 1

    local type

    type=$(result_field_type "$field")

    case "$type" in

        enum)

            validate_type enum \
                "$value" \
                "${RESULT_STATUS_ENUM[@]}"
            ;;

        *)

            validate_type "$type" "$value"
            ;;

    esac

}

############################################################
# Assertions
############################################################

assert_provider() {

    provider_valid "$1"

}

assert_workload() {

    workload_valid "$1"

}

assert_result_field() {

    result_field_valid "$1"

}

assert_result_value() {

    result_value_valid "$1" "$2"

}

assert_result_status() {

    result_status_valid "$1"

}

assert_output_format() {

    output_format_valid "$1"

}

############################################################
# Repository Validation
############################################################

result_required_fields_present() {

    local getter="$1"

    local field

    for field in "${RESULT_FIELD_ENUM[@]}"
    do

        if result_field_required "$field"
        then

            local value

            value=$($getter "$field")

            [[ -z "$value" ]] && return 1

        fi

    done

    return 0

}