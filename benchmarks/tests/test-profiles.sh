#!/usr/bin/env bash
set -u

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BENCHMARKS_DIR="$(cd "${TEST_DIR}/.." && pwd)"
source "${BENCHMARKS_DIR}/lib/core/profile.sh"

PASS_COUNT=0
FAIL_COUNT=0
pass(){ PASS_COUNT=$((PASS_COUNT+1)); printf "PASS: %s\n" "$1"; }
fail(){ FAIL_COUNT=$((FAIL_COUNT+1)); printf "FAIL: %s\n" "$1" >&2; }
assert_success(){ local d="$1"; shift; if "$@"; then pass "$d"; else fail "$d"; fi; }
assert_equals(){ local d="$1" e="$2" a="$3"; if [ "$e" = "$a" ]; then pass "$d"; else fail "$d (expected='$e', actual='$a')"; fi; }
assert_nonempty(){ local d="$1" v="$2"; if [ -n "$v" ]; then pass "$d"; else fail "$d"; fi; }

pass "profile.sh loads"
assert_success "quick profile exists" profile_exists quick
assert_success "standard profile exists" profile_exists standard
assert_success "extended profile exists" profile_exists extended
assert_success "stress profile exists" profile_exists stress
assert_success "standard profile loads" profile_load standard
assert_equals "Profile name is standard" standard "$PROFILE_NAME"
assert_nonempty "Profile iterations are loaded" "$PROFILE_ITERATIONS"
assert_nonempty "Profile timeout is loaded" "$PROFILE_TIMEOUT_SECONDS"
assert_success "Loaded profile validates" profile_validate
assert_nonempty "Profile list is returned" "$(profiles_list)"

printf "\nPassed: %s\nFailed: %s\n" "$PASS_COUNT" "$FAIL_COUNT"
[ "$FAIL_COUNT" -eq 0 ]
