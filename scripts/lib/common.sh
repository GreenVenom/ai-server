#!/bin/bash

PASS_COUNT=0
WARN_COUNT=0
FAIL_COUNT=0

PASS="[PASS]"
WARN="[WARN]"
FAIL="[FAIL]"
INFO="[INFO]"

timestamp() {
    date "+%Y-%m-%d %H:%M:%S"
}

pass() {
    ((PASS_COUNT++))
    printf "%s %s %s\n" "$(timestamp)" "$PASS" "$1"
}

warn() {
    ((WARN_COUNT++))
    printf "%s %s %s\n" "$(timestamp)" "$WARN" "$1"
}

fail() {
    ((FAIL_COUNT++))
    printf "%s %s %s\n" "$(timestamp)" "$FAIL" "$1"
}

info() {
    printf "%s %s %s\n" "$(timestamp)" "$INFO" "$1"
}

header() {
    echo
    echo "============================================"
    echo "$1"
    echo "============================================"
}

summary() {

    echo

    echo "--------------------------------------------"

    echo "PASS : $PASS_COUNT"

    echo "WARN : $WARN_COUNT"

    echo "FAIL : $FAIL_COUNT"

    echo "--------------------------------------------"

    if [[ $FAIL_COUNT -eq 0 ]]; then
        return 0
    else
        return 1
    fi
}