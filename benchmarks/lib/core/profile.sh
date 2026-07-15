#!/usr/bin/env bash
[[ -n "${BENCHMARK_PROFILE_LOADED:-}" ]] && return 0
BENCHMARK_PROFILE_LOADED=1

PROFILE_CORE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROFILE_LIB_DIR="$(cd "${PROFILE_CORE_DIR}/.." && pwd)"
PROFILE_BENCHMARKS_DIR="$(cd "${PROFILE_LIB_DIR}/.." && pwd)"
PROFILE_DIR="${PROFILE_BENCHMARKS_DIR}/profiles"

source "${PROFILE_CORE_DIR}/definitions.sh"
source "${PROFILE_CORE_DIR}/validators.sh"

PROFILE_NAME=""
PROFILE_ITERATIONS="$DEFAULT_ITERATIONS"
PROFILE_TIMEOUT_SECONDS="$DEFAULT_TIMEOUT_SECONDS"
PROFILE_MEASURE_MEMORY="false"
PROFILE_MEASURE_CPU="false"
PROFILE_COLD_START="false"
PROFILE_WARM_START="true"
PROFILE_WORKLOADS=()
PROFILE_WORKLOAD_COUNT=0

profile_reset() {
    PROFILE_NAME=""
    PROFILE_ITERATIONS="$DEFAULT_ITERATIONS"
    PROFILE_TIMEOUT_SECONDS="$DEFAULT_TIMEOUT_SECONDS"
    PROFILE_MEASURE_MEMORY="false"
    PROFILE_MEASURE_CPU="false"
    PROFILE_COLD_START="false"
    PROFILE_WARM_START="true"
    PROFILE_WORKLOADS=()
    PROFILE_WORKLOAD_COUNT=0
}

profile_file() {
    local name="$1"
    [ -n "$name" ] || return "$EXIT_INVALID_ARGUMENT"
    printf "%s/%s.profile\n" "$PROFILE_DIR" "$name"
}

profile_exists() {
    local file
    file="$(profile_file "$1")" || return 1
    [ -f "$file" ] && [ -s "$file" ]
}

_profile_bool_normalize() {
    case "$1" in
        true|TRUE|1|yes|YES) printf "true\n" ;;
        false|FALSE|0|no|NO) printf "false\n" ;;
        *) return 1 ;;
    esac
}

_profile_add_workload() {
    local workload="$1"
    workload_valid "$workload" || return "$EXIT_WORKLOAD_NOT_FOUND"
    PROFILE_WORKLOADS[$PROFILE_WORKLOAD_COUNT]="$workload"
    PROFILE_WORKLOAD_COUNT=$((PROFILE_WORKLOAD_COUNT + 1))
}

profile_load() {
    local name="$1"
    local file
    file="$(profile_file "$name")" || return "$EXIT_INVALID_ARGUMENT"
    [ -f "$file" ] || return "$EXIT_FAILURE"

    profile_reset

    unset ITERATIONS TIMEOUT TIMEOUT_SECONDS MEASURE_MEMORY MEASURE_CPU COLD_START WARM_START WORKLOADS

    source "$file"

    PROFILE_NAME="$name"
    PROFILE_ITERATIONS="${ITERATIONS:-$PROFILE_ITERATIONS}"
    PROFILE_TIMEOUT_SECONDS="${TIMEOUT_SECONDS:-${TIMEOUT:-$PROFILE_TIMEOUT_SECONDS}}"

    PROFILE_MEASURE_MEMORY="$(_profile_bool_normalize "${MEASURE_MEMORY:-$PROFILE_MEASURE_MEMORY}")" || return "$EXIT_INVALID_ARGUMENT"
    PROFILE_MEASURE_CPU="$(_profile_bool_normalize "${MEASURE_CPU:-$PROFILE_MEASURE_CPU}")" || return "$EXIT_INVALID_ARGUMENT"
    PROFILE_COLD_START="$(_profile_bool_normalize "${COLD_START:-$PROFILE_COLD_START}")" || return "$EXIT_INVALID_ARGUMENT"
    PROFILE_WARM_START="$(_profile_bool_normalize "${WARM_START:-$PROFILE_WARM_START}")" || return "$EXIT_INVALID_ARGUMENT"

    PROFILE_WORKLOADS=()
    PROFILE_WORKLOAD_COUNT=0

    if [ -n "${WORKLOADS:-}" ]; then
        local workload
        for workload in $WORKLOADS; do
            _profile_add_workload "$workload" || return $?
        done
    fi

    profile_validate
}

profile_validate() {
    [ -n "$PROFILE_NAME" ] || return "$EXIT_INVALID_ARGUMENT"
    is_integer "$PROFILE_ITERATIONS" || return "$EXIT_INVALID_ARGUMENT"
    [ "$PROFILE_ITERATIONS" -gt 0 ] || return "$EXIT_INVALID_ARGUMENT"
    is_integer "$PROFILE_TIMEOUT_SECONDS" || return "$EXIT_INVALID_ARGUMENT"
    [ "$PROFILE_TIMEOUT_SECONDS" -gt 0 ] || return "$EXIT_INVALID_ARGUMENT"

    local i=0
    while [ "$i" -lt "$PROFILE_WORKLOAD_COUNT" ]; do
        workload_valid "${PROFILE_WORKLOADS[$i]}" || return "$EXIT_WORKLOAD_NOT_FOUND"
        i=$((i + 1))
    done

    return "$EXIT_SUCCESS"
}

profile_workloads_count() {
    printf "%s\n" "$PROFILE_WORKLOAD_COUNT"
}

profile_workloads_list() {
    local i=0
    while [ "$i" -lt "$PROFILE_WORKLOAD_COUNT" ]; do
        printf "%s\n" "${PROFILE_WORKLOADS[$i]}"
        i=$((i + 1))
    done
}

profiles_list() {
    local file
    for file in "${PROFILE_DIR}"/*.profile; do
        [ -f "$file" ] || continue
        basename "$file" .profile
    done
}
