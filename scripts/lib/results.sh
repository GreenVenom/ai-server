#!/bin/bash

############################################################
#
# Personal AI Platform
#
# Script: results.sh
#
# Purpose:
# Central result and execution context manager.
#
# Version: 2.1.0
#
############################################################

STATUS_PASS="PASS"
STATUS_WARN="WARN"
STATUS_FAIL="FAIL"

SEVERITY_INFO="INFO"
SEVERITY_LOW="LOW"
SEVERITY_MEDIUM="MEDIUM"
SEVERITY_HIGH="HIGH"
SEVERITY_CRITICAL="CRITICAL"

PASS_COUNT=0
WARN_COUNT=0
FAIL_COUNT=0
CHECK_COUNT=0

START_TIME=$(date +%s)

RESULT_STATUS=""
RESULT_COMPONENT=""
RESULT_MESSAGE=""
RESULT_SEVERITY="$SEVERITY_INFO"

reset_result() {
    RESULT_STATUS=""
    RESULT_COMPONENT=""
    RESULT_MESSAGE=""
    RESULT_SEVERITY="$SEVERITY_INFO"
}

pass() {
    RESULT_STATUS="$STATUS_PASS"
    RESULT_COMPONENT="$1"
    RESULT_MESSAGE="$2"
    RESULT_SEVERITY="${3:-$SEVERITY_INFO}"
}

warn() {
    RESULT_STATUS="$STATUS_WARN"
    RESULT_COMPONENT="$1"
    RESULT_MESSAGE="$2"
    RESULT_SEVERITY="${3:-$SEVERITY_LOW}"
}

fail() {
    RESULT_STATUS="$STATUS_FAIL"
    RESULT_COMPONENT="$1"
    RESULT_MESSAGE="$2"
    RESULT_SEVERITY="${3:-$SEVERITY_HIGH}"
}

overall_status() {
    if (( FAIL_COUNT > 0 )); then
        printf "FAIL\n"
    elif (( WARN_COUNT > 0 )); then
        printf "WARN\n"
    else
        printf "PASS\n"
    fi
}

print_summary() {
    local end_time
    local duration

    end_time=$(date +%s)
    duration=$((end_time - START_TIME))

    print_section "Summary"

    printf "Checks   : %s\n" "$CHECK_COUNT"
    printf "Passed   : %s\n" "$PASS_COUNT"
    printf "Warnings : %s\n" "$WARN_COUNT"
    printf "Failed   : %s\n" "$FAIL_COUNT"
    printf "Duration : %ss\n" "$duration"
    printf "Overall  : %s\n" "$(overall_status)"
}
