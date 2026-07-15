#!/usr/bin/env bash
#
# ============================================================
# Personal AI Platform
# Benchmark Framework
#
# File: test-providers.sh
#
# Purpose:
#   Smoke-test the Provider API and Ollama implementation.
#
# Usage:
#   ./benchmarks/tests/test-providers.sh
#
# Notes:
#   This is an integration test. It expects:
#   - Ollama to be running
#   - OLLAMA_HOST to be reachable
#   - At least one installed generation model
#   - nomic-embed-text for embedding validation when installed
#
# Exit Codes:
#   0 - all tests passed
#   1 - one or more tests failed
# ============================================================

set -u

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BENCHMARKS_DIR="$(cd "${TEST_DIR}/.." && pwd)"
API_DIR="${BENCHMARKS_DIR}/lib/api"

PASS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0

pass() {
    PASS_COUNT=$((PASS_COUNT + 1))
    printf "PASS: %s\n" "$1"
}

fail() {
    FAIL_COUNT=$((FAIL_COUNT + 1))
    printf "FAIL: %s\n" "$1" >&2
}

skip() {
    SKIP_COUNT=$((SKIP_COUNT + 1))
    printf "SKIP: %s\n" "$1"
}

assert_success() {
    local description="$1"
    shift

    if "$@"; then
        pass "$description"
    else
        fail "$description"
    fi
}

assert_failure() {
    local description="$1"
    shift

    if "$@"; then
        fail "$description"
    else
        pass "$description"
    fi
}

assert_nonempty() {
    local description="$1"
    local value="$2"

    if [ -n "$value" ]; then
        pass "$description"
    else
        fail "$description"
    fi
}

assert_contains_line() {
    local description="$1"
    local expected="$2"
    local input="$3"
    local line

    while IFS= read -r line; do
        if [ "$line" = "$expected" ]; then
            pass "$description"
            return 0
        fi
    done <<EOF
$input
EOF

    fail "$description"
    return 1
}

printf "============================================================\n"
printf "Benchmark Framework Provider API Smoke Test\n"
printf "============================================================\n\n"

# ------------------------------------------------------------
# Load framework
# ------------------------------------------------------------

if source "${API_DIR}/errors.sh"; then
    pass "errors.sh loads"
else
    fail "errors.sh loads"
    exit 1
fi

if source "${API_DIR}/providers.sh"; then
    pass "providers.sh loads"
else
    fail "providers.sh loads"
    exit 1
fi

assert_success "Error repository resets" errors_reset

# ------------------------------------------------------------
# Provider registry
# ------------------------------------------------------------

assert_success \
    "Ollama exists in provider registry" \
    provider_exists "$PROVIDER_OLLAMA"

assert_failure \
    "Unknown provider is rejected by predicate" \
    provider_exists "not-a-provider"

# ------------------------------------------------------------
# Provider availability
# ------------------------------------------------------------

if provider_available "$PROVIDER_OLLAMA"; then
    pass "Ollama provider is available"
else
    fail "Ollama provider is available"
    printf "\nCannot continue live provider tests because Ollama is unavailable.\n" >&2
    printf "OLLAMA_HOST=%s\n" "$OLLAMA_HOST" >&2
    printf "\nPassed: %s\nFailed: %s\nSkipped: %s\n" \
        "$PASS_COUNT" "$FAIL_COUNT" "$SKIP_COUNT"
    exit 1
fi

# ------------------------------------------------------------
# Version
# ------------------------------------------------------------

OLLAMA_VERSION="$(provider_version "$PROVIDER_OLLAMA" 2>/dev/null || true)"
assert_nonempty "Ollama version is returned" "$OLLAMA_VERSION"

# ------------------------------------------------------------
# Model enumeration
# ------------------------------------------------------------

MODEL_LIST="$(provider_models "$PROVIDER_OLLAMA" 2>/dev/null || true)"
assert_nonempty "Provider model list is returned" "$MODEL_LIST"

GENERATION_MODEL=""

for candidate in \
    "qwen3:14b" \
    "gemma4:12b" \
    "gemma3:12b"
do
    if provider_model_exists "$PROVIDER_OLLAMA" "$candidate"; then
        GENERATION_MODEL="$candidate"
        break
    fi
done

if [ -z "$GENERATION_MODEL" ]; then
    GENERATION_MODEL="$(printf "%s\n" "$MODEL_LIST" | head -n 1)"
fi

assert_nonempty "A generation model is available for live testing" "$GENERATION_MODEL"

if [ -n "$GENERATION_MODEL" ]; then
    assert_success \
        "Selected generation model exists" \
        provider_model_exists "$PROVIDER_OLLAMA" "$GENERATION_MODEL"

    assert_contains_line \
        "Selected generation model appears in model list" \
        "$GENERATION_MODEL" \
        "$MODEL_LIST"
fi

assert_failure \
    "Missing model is rejected by predicate" \
    provider_model_exists "$PROVIDER_OLLAMA" "definitely-not-installed:model"

# ------------------------------------------------------------
# Text generation
# ------------------------------------------------------------

if [ -n "$GENERATION_MODEL" ]; then
    GENERATION_RESPONSE="$(
        provider_generate \
            "$PROVIDER_OLLAMA" \
            "$GENERATION_MODEL" \
            "Reply with exactly the word READY." \
            "60" 2>/dev/null || true
    )"

    assert_nonempty \
        "Text generation returns a provider response" \
        "$GENERATION_RESPONSE"

    if command -v python3 >/dev/null 2>&1 && [ -n "$GENERATION_RESPONSE" ]; then
        if printf "%s" "$GENERATION_RESPONSE" \
            | python3 -m json.tool >/dev/null 2>&1
        then
            pass "Generation response is valid JSON"
        else
            fail "Generation response is valid JSON"
        fi

        GENERATED_TEXT="$(
            printf "%s" "$GENERATION_RESPONSE" | python3 -c '
import json
import sys

try:
    data = json.load(sys.stdin)
    print(data.get("response", ""))
except Exception:
    pass
'
        )"

        assert_nonempty \
            "Generation response contains generated text" \
            "$GENERATED_TEXT"
    else
        skip "Generation JSON structure validation (python3 unavailable or empty response)"
    fi
fi

# ------------------------------------------------------------
# Embeddings
# ------------------------------------------------------------

EMBEDDING_MODEL="nomic-embed-text"

if provider_model_exists "$PROVIDER_OLLAMA" "$EMBEDDING_MODEL"; then
    pass "Embedding model is installed"

    EMBEDDING_RESPONSE="$(
        provider_embeddings \
            "$PROVIDER_OLLAMA" \
            "$EMBEDDING_MODEL" \
            "Benchmark framework embedding smoke test." \
            "60" 2>/dev/null || true
    )"

    assert_nonempty \
        "Embedding request returns a provider response" \
        "$EMBEDDING_RESPONSE"

    if command -v python3 >/dev/null 2>&1 && [ -n "$EMBEDDING_RESPONSE" ]; then
        if printf "%s" "$EMBEDDING_RESPONSE" \
            | python3 -m json.tool >/dev/null 2>&1
        then
            pass "Embedding response is valid JSON"
        else
            fail "Embedding response is valid JSON"
        fi

        EMBEDDING_COUNT="$(
            printf "%s" "$EMBEDDING_RESPONSE" | python3 -c '
import json
import sys

try:
    data = json.load(sys.stdin)
    embeddings = data.get("embeddings", [])
    if embeddings and isinstance(embeddings[0], list):
        print(len(embeddings[0]))
    else:
        print(0)
except Exception:
    print(0)
'
        )"

        if [ "${EMBEDDING_COUNT:-0}" -gt 0 ] 2>/dev/null; then
            pass "Embedding response contains a non-empty vector"
        else
            fail "Embedding response contains a non-empty vector"
        fi
    else
        skip "Embedding JSON structure validation (python3 unavailable or empty response)"
    fi
else
    skip "Embedding test because nomic-embed-text is not installed"
fi

# ------------------------------------------------------------
# Structured error integration
# ------------------------------------------------------------

ERRORS_BEFORE="$(errors_count)"

if provider_version "not-a-provider" >/dev/null 2>&1; then
    fail "Invalid provider operation is rejected"
else
    pass "Invalid provider operation is rejected"
fi

ERRORS_AFTER="$(errors_count)"

if [ "$ERRORS_AFTER" -gt "$ERRORS_BEFORE" ]; then
    pass "Invalid provider operation creates an Error Repository entry"
else
    fail "Invalid provider operation creates an Error Repository entry"
fi

LAST_ERROR_ID="$(error_last || true)"
assert_nonempty "Last provider error ID is available" "$LAST_ERROR_ID"

if [ -n "$LAST_ERROR_ID" ]; then
    assert_success \
        "Last provider error validates" \
        error_validate "$LAST_ERROR_ID"
fi

ERRORS_BEFORE="$(errors_count)"

if provider_generate \
    "$PROVIDER_OLLAMA" \
    "definitely-not-installed:model" \
    "test" \
    "10" >/dev/null 2>&1
then
    fail "Generation with missing model is rejected"
else
    pass "Generation with missing model is rejected"
fi

ERRORS_AFTER="$(errors_count)"

if [ "$ERRORS_AFTER" -gt "$ERRORS_BEFORE" ]; then
    pass "Missing model failure creates an Error Repository entry"
else
    fail "Missing model failure creates an Error Repository entry"
fi

# ------------------------------------------------------------
# Summary
# ------------------------------------------------------------

printf "\n============================================================\n"
printf "Smoke Test Summary\n"
printf "============================================================\n"
printf "Passed:  %s\n" "$PASS_COUNT"
printf "Failed:  %s\n" "$FAIL_COUNT"
printf "Skipped: %s\n" "$SKIP_COUNT"

if [ "$FAIL_COUNT" -gt 0 ]; then
    printf "\nResult: FAILED\n" >&2
    exit 1
fi

printf "\nResult: PASSED\n"
exit 0
