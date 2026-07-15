#!/usr/bin/env bash
#
# ============================================================
# Personal AI Platform
# Benchmark Framework
#
# File: test-models.sh
#
# Purpose:
#   Smoke-test the model API against the live provider layer.
#
# Usage:
#   ./benchmarks/tests/test-models.sh
#
# Compatibility:
#   - Bash 3.2+
# ============================================================

set -u

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BENCHMARKS_DIR="$(cd "${TEST_DIR}/.." && pwd)"
API_DIR="${BENCHMARKS_DIR}/lib/api"

PASS_COUNT=0
FAIL_COUNT=0

pass() { PASS_COUNT=$((PASS_COUNT + 1)); printf "PASS: %s\n" "$1"; }
fail() { FAIL_COUNT=$((FAIL_COUNT + 1)); printf "FAIL: %s\n" "$1" >&2; }

assert_success() {
    local description="$1"
    shift
    if "$@"; then pass "$description"; else fail "$description"; fi
}

assert_failure() {
    local description="$1"
    shift
    if "$@"; then fail "$description"; else pass "$description"; fi
}

assert_equals() {
    local description="$1"
    local expected="$2"
    local actual="$3"

    if [ "$expected" = "$actual" ]; then
        pass "$description"
    else
        fail "$description (expected='${expected}', actual='${actual}')"
    fi
}

assert_nonempty() {
    local description="$1"
    local value="$2"

    if [ -n "$value" ]; then pass "$description"; else fail "$description"; fi
}

printf "============================================================\n"
printf "Benchmark Framework Model API Smoke Test\n"
printf "============================================================\n\n"

if source "${API_DIR}/models.sh"; then
    pass "models.sh loads"
else
    fail "models.sh loads"
    exit 1
fi

assert_success "Ollama provider is available" provider_available "$PROVIDER_OLLAMA"

assert_equals \
    "Untagged model normalizes to latest" \
    "nomic-embed-text:latest" \
    "$(model_normalize "nomic-embed-text")"

assert_equals \
    "Tagged model is preserved" \
    "qwen3:14b" \
    "$(model_normalize "qwen3:14b")"

assert_equals \
    "Base model name strips tag" \
    "qwen3" \
    "$(model_base_name "qwen3:14b")"

MODEL_LIST="$(models_list "$PROVIDER_OLLAMA")"
assert_nonempty "Live model list is returned" "$MODEL_LIST"

assert_success \
    "qwen3:14b exists" \
    model_exists "$PROVIDER_OLLAMA" "qwen3:14b"

assert_success \
    "gemma4:12b exists" \
    model_exists "$PROVIDER_OLLAMA" "gemma4:12b"

assert_success \
    "nomic-embed-text resolves without explicit latest tag" \
    model_exists "$PROVIDER_OLLAMA" "nomic-embed-text"

assert_success \
    "nomic-embed-text:latest exists" \
    model_exists "$PROVIDER_OLLAMA" "nomic-embed-text:latest"

assert_failure \
    "Missing model does not exist" \
    model_exists "$PROVIDER_OLLAMA" "definitely-not-installed:model"

assert_success \
    "nomic-embed-text is classified as embedding" \
    model_is_embedding "nomic-embed-text"

assert_success \
    "nomic-embed-text:latest is classified as embedding" \
    model_is_embedding "nomic-embed-text:latest"

assert_failure \
    "qwen3:14b is not classified as embedding" \
    model_is_embedding "qwen3:14b"

assert_success \
    "qwen3:14b is classified as generation" \
    model_is_generation "qwen3:14b"

PREFERRED_GENERATION="$(model_preferred_generation "$PROVIDER_OLLAMA")"
assert_nonempty \
    "Preferred generation model is selected" \
    "$PREFERRED_GENERATION"

assert_success \
    "Preferred generation model exists" \
    model_exists "$PROVIDER_OLLAMA" "$PREFERRED_GENERATION"

PREFERRED_EMBEDDING="$(model_preferred_embedding "$PROVIDER_OLLAMA")"
assert_nonempty \
    "Preferred embedding model is selected" \
    "$PREFERRED_EMBEDDING"

assert_success \
    "Preferred embedding model exists" \
    model_exists "$PROVIDER_OLLAMA" "$PREFERRED_EMBEDDING"

GENERATION_MODELS="$(models_generation "$PROVIDER_OLLAMA")"
assert_nonempty \
    "Generation model list is non-empty" \
    "$GENERATION_MODELS"

EMBEDDING_MODELS="$(models_embeddings "$PROVIDER_OLLAMA")"
assert_nonempty \
    "Embedding model list is non-empty" \
    "$EMBEDDING_MODELS"

printf "\n============================================================\n"
printf "Smoke Test Summary\n"
printf "============================================================\n"
printf "Passed: %s\n" "$PASS_COUNT"
printf "Failed: %s\n" "$FAIL_COUNT"

if [ "$FAIL_COUNT" -gt 0 ]; then
    printf "\nResult: FAILED\n" >&2
    exit 1
fi

printf "\nResult: PASSED\n"
exit 0
