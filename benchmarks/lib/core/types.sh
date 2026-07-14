#!/usr/bin/env bash
#
# ============================================================
# Personal AI Platform
# Benchmark Framework
#
# File: types.sh
#
# Purpose:
#   Primitive type validation library.
#
# This library provides validation helpers used throughout
# the Benchmark Framework.
#
# It intentionally knows nothing about providers,
# workloads, benchmark jobs, or results.
#
# ============================================================

[[ -n "${BENCHMARK_TYPES_LOADED:-}" ]] && return
readonly BENCHMARK_TYPES_LOADED=1

############################################################
# Basic Types
############################################################

is_string() {

    return 0

}

is_integer() {

    [[ "$1" =~ ^-?[0-9]+$ ]]

}

is_float() {

    [[ "$1" =~ ^-?[0-9]+([.][0-9]+)?$ ]]

}

is_boolean() {

    case "$1" in

        true|false|1|0|yes|no)

            return 0
            ;;

    esac

    return 1

}

############################################################
# Filesystem Types
############################################################

is_path() {

    [[ -n "$1" ]]

}

is_file() {

    [[ -f "$1" ]]

}

is_directory() {

    [[ -d "$1" ]]

}

############################################################
# Structured Types
############################################################

is_datetime() {

    [[ "$1" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T ]]

}

is_json() {

    command -v jq >/dev/null 2>&1 || return 1

    echo "$1" | jq empty >/dev/null 2>&1

}

is_url() {

    [[ "$1" =~ ^https?:// ]]

}

############################################################
# Enumeration
############################################################

is_enum() {

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
# Generic Dispatcher
############################################################

validate_type() {

    local type="$1"

    local value="$2"

    shift 2

    case "$type" in

        string)

            is_string "$value"
            ;;

        integer)

            is_integer "$value"
            ;;

        float)

            is_float "$value"
            ;;

        boolean)

            is_boolean "$value"
            ;;

        datetime)

            is_datetime "$value"
            ;;

        path)

            is_path "$value"
            ;;

        file)

            is_file "$value"
            ;;

        directory)

            is_directory "$value"
            ;;

        json)

            is_json "$value"
            ;;

        url)

            is_url "$value"
            ;;

        enum)

            is_enum "$value" "$@"
            ;;

        *)

            return 1
            ;;

    esac

}

############################################################
# Introspection
############################################################

supported_type() {

    case "$1" in

        string|integer|float|boolean|datetime|enum|path|file|directory|json|url)

            return 0
            ;;

    esac

    return 1

}

list_types() {

cat <<EOF
string
integer
float
boolean
datetime
enum
path
file
directory
json
url
EOF

}