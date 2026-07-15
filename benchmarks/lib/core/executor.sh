#!/usr/bin/env bash
#
# ============================================================
# Personal AI Platform
# Benchmark Framework
#
# File: executor.sh
#
# Purpose:
#   Executes benchmark workloads through the provider layer and
#   records execution state in the Result Repository.
#
# Responsibilities:
#   - Result creation
#   - Workload prompt loading
#   - Provider execution
#   - Timing
#   - Output capture
#   - Result lifecycle transitions
#   - Error propagation into Result objects
#
# Design:
#   - Core orchestration only
#   - Uses public APIs from results.sh, providers.sh, models.sh,
#     and prompts.sh
#   - Mutating repository functions execute in the current shell
#   - Supports text generation and embedding workloads
#
# Compatibility:
#   - Bash 3.2+
# ============================================================

[[ -n "${BENCHMARK_EXECUTOR_LOADED:-}" ]] && return 0
BENCHMARK_EXECUTOR_LOADED=1

EXECUTOR_CORE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXECUTOR_LIB_DIR="$(cd "${EXECUTOR_CORE_DIR}/.." && pwd)"
EXECUTOR_API_DIR="${EXECUTOR_LIB_DIR}/api"

# shellcheck source=/dev/null
source "${EXECUTOR_API_DIR}/results.sh"

# shellcheck source=/dev/null
source "${EXECUTOR_API_DIR}/providers.sh"

# shellcheck source=/dev/null
source "${EXECUTOR_API_DIR}/models.sh"

# shellcheck source=/dev/null
source "${EXECUTOR_API_DIR}/prompts.sh"

# ------------------------------------------------------------
# Internal timing helpers
# ------------------------------------------------------------

_executor_now_ms() {
    if command -v python3 >/dev/null 2>&1; then
        python3 -c 'import time; print(int(time.time() * 1000))'
        return $?
    fi

    # Fallback: second precision converted to milliseconds.
    printf "%s000\n" "$(date +%s)"
}

_executor_duration_seconds() {
    local duration_ms="$1"

    if command -v python3 >/dev/null 2>&1; then
        python3 - "$duration_ms" <<'PY'
import sys
value = int(sys.argv[1])
print(f"{value / 1000:.3f}")
PY
        return $?
    fi

    awk "BEGIN { printf \"%.3f\n\", ${duration_ms}/1000 }"
}

_executor_tokens_per_second() {
    local tokens="$1"
    local seconds="$2"

    if [ -z "$tokens" ] || [ -z "$seconds" ]; then
        return 1
    fi

    if command -v python3 >/dev/null 2>&1; then
        python3 - "$tokens" "$seconds" <<'PY'
import sys
tokens = float(sys.argv[1])
seconds = float(sys.argv[2])
if seconds <= 0:
    print("0.0")
else:
    print(f"{tokens / seconds:.3f}")
PY
        return $?
    fi

    awk "BEGIN { if (${seconds} <= 0) print \"0.0\"; else printf \"%.3f\n\", ${tokens}/${seconds} }"
}

_executor_estimate_tokens() {
    local text="$1"

    if [ -z "$text" ]; then
        printf "0\n"
        return 0
    fi

    # Approximation only. Provider-reported token metrics should
    # replace this when available from provider response metadata.
    if command -v python3 >/dev/null 2>&1; then
        printf "%s" "$text" | python3 -c '
import sys
text = sys.stdin.read()
words = len(text.split())
print(max(1, round(words * 1.33)))
'
        return $?
    fi

    local words
    words="$(printf "%s" "$text" | wc -w | tr -d ' ')"
    printf "%s\n" "$words"
}

# ------------------------------------------------------------
# Provider response parsing
# ------------------------------------------------------------

_executor_parse_generation_text() {
    local response="$1"

    if command -v python3 >/dev/null 2>&1; then
        printf "%s" "$response" | python3 -c '
import json
import sys

try:
    data = json.load(sys.stdin)
    print(data.get("response", ""))
except Exception:
    pass
'
        return $?
    fi

    printf "%s\n" "$response"
}

_executor_parse_generation_tokens() {
    local response="$1"

    if command -v python3 >/dev/null 2>&1; then
        printf "%s" "$response" | python3 -c '
import json
import sys

try:
    data = json.load(sys.stdin)
    value = data.get("eval_count")
    print("" if value is None else value)
except Exception:
    pass
'
        return $?
    fi

    return 1
}

_executor_parse_generation_eval_duration_ns() {
    local response="$1"

    if command -v python3 >/dev/null 2>&1; then
        printf "%s" "$response" | python3 -c '
import json
import sys

try:
    data = json.load(sys.stdin)
    value = data.get("eval_duration")
    print("" if value is None else value)
except Exception:
    pass
'
        return $?
    fi

    return 1
}

_executor_eval_tokens_per_second() {
    local tokens="$1"
    local eval_duration_ns="$2"

    [ -n "$tokens" ] || return 1
    [ -n "$eval_duration_ns" ] || return 1

    if command -v python3 >/dev/null 2>&1; then
        python3 - "$tokens" "$eval_duration_ns" <<'PY'
import sys
tokens = float(sys.argv[1])
duration_ns = float(sys.argv[2])
seconds = duration_ns / 1_000_000_000
if seconds <= 0:
    print("0.0")
else:
    print(f"{tokens / seconds:.3f}")
PY
        return $?
    fi

    return 1
}

_executor_parse_embedding_count() {
    local response="$1"

    if command -v python3 >/dev/null 2>&1; then
        printf "%s" "$response" | python3 -c '
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
        return $?
    fi

    printf "0\n"
}

# ------------------------------------------------------------
# Error extraction
# ------------------------------------------------------------

_executor_last_error_message() {
    local id
    local message

    id="$(error_last 2>/dev/null || true)"

    if [ -z "$id" ]; then
        return 1
    fi

    message="$(error_message_get "$id" 2>/dev/null || true)"

    if [ -n "$message" ]; then
        printf "%s\n" "$message"
        return 0
    fi

    return 1
}

# ------------------------------------------------------------
# Result creation
# ------------------------------------------------------------

executor_create_result() {
    local provider="$1"
    local model="$2"
    local profile="$3"
    local workload="$4"
    local prompt="$5"

    result_create \
        "$provider" \
        "$model" \
        "$profile" \
        "$workload" \
        "$prompt"
}

# ------------------------------------------------------------
# Text generation execution
# ------------------------------------------------------------

_executor_execute_generation() {
    local result_id="$1"
    local provider="$2"
    local model="$3"
    local prompt="$4"
    local timeout_seconds="$5"

    local start_ms
    local end_ms
    local duration_ms
    local duration_seconds
    local response
    local generated_text
    local tokens
    local eval_duration_ns
    local tokens_per_second
    local exit_code

    start_ms="$(_executor_now_ms)"

    response="$(
        provider_generate \
            "$provider" \
            "$model" \
            "$prompt" \
            "$timeout_seconds" 2>/dev/null
    )"
    exit_code=$?

    end_ms="$(_executor_now_ms)"
    duration_ms=$((end_ms - start_ms))
    duration_seconds="$(_executor_duration_seconds "$duration_ms")"

    result_duration_ms_set "$result_id" "$duration_ms" || return "$EXIT_FAILURE"
    result_duration_seconds_set "$result_id" "$duration_seconds" || return "$EXIT_FAILURE"

    if [ "$exit_code" -ne 0 ]; then
        local error_message

        error_message="$(_executor_last_error_message || true)"
        [ -n "$error_message" ] || error_message="Provider generation failed."

        result_mark_failed "$result_id" "$error_message" "$exit_code"
        return "$exit_code"
    fi

    generated_text="$(_executor_parse_generation_text "$response")"

    result_output_set "$result_id" "$generated_text" || return "$EXIT_FAILURE"

    tokens="$(_executor_parse_generation_tokens "$response" || true)"
    eval_duration_ns="$(_executor_parse_generation_eval_duration_ns "$response" || true)"

    if [ -z "$tokens" ]; then
        tokens="$(_executor_estimate_tokens "$generated_text")"
    fi

    result_tokens_set "$result_id" "$tokens" || return "$EXIT_FAILURE"

    if [ -n "$eval_duration_ns" ]; then
        tokens_per_second="$(
            _executor_eval_tokens_per_second \
                "$tokens" \
                "$eval_duration_ns" 2>/dev/null || true
        )"
    else
        tokens_per_second="$(
            _executor_tokens_per_second \
                "$tokens" \
                "$duration_seconds" 2>/dev/null || true
        )"
    fi

    if [ -n "$tokens_per_second" ]; then
        result_tokens_per_second_set "$result_id" "$tokens_per_second" || return "$EXIT_FAILURE"
    fi

    result_mark_completed "$result_id" "0"
}

# ------------------------------------------------------------
# Embedding execution
# ------------------------------------------------------------

_executor_execute_embedding() {
    local result_id="$1"
    local provider="$2"
    local model="$3"
    local input="$4"
    local timeout_seconds="$5"

    local start_ms
    local end_ms
    local duration_ms
    local duration_seconds
    local response
    local embedding_dimensions
    local exit_code

    start_ms="$(_executor_now_ms)"

    response="$(
        provider_embeddings \
            "$provider" \
            "$model" \
            "$input" \
            "$timeout_seconds" 2>/dev/null
    )"
    exit_code=$?

    end_ms="$(_executor_now_ms)"
    duration_ms=$((end_ms - start_ms))
    duration_seconds="$(_executor_duration_seconds "$duration_ms")"

    result_duration_ms_set "$result_id" "$duration_ms" || return "$EXIT_FAILURE"
    result_duration_seconds_set "$result_id" "$duration_seconds" || return "$EXIT_FAILURE"

    if [ "$exit_code" -ne 0 ]; then
        local error_message

        error_message="$(_executor_last_error_message || true)"
        [ -n "$error_message" ] || error_message="Provider embedding request failed."

        result_mark_failed "$result_id" "$error_message" "$exit_code"
        return "$exit_code"
    fi

    embedding_dimensions="$(_executor_parse_embedding_count "$response")"

    result_output_set "$result_id" "$response" || return "$EXIT_FAILURE"
    result_tokens_set "$result_id" "$embedding_dimensions" || return "$EXIT_FAILURE"

    result_mark_completed "$result_id" "0"
}

# ------------------------------------------------------------
# Public execution API
# ------------------------------------------------------------

executor_execute_prompt() {
    local provider="$1"
    local model="$2"
    local profile="$3"
    local workload="$4"
    local prompt="$5"
    local timeout_seconds="${6:-$DEFAULT_TIMEOUT_SECONDS}"

    local result_id

    if ! provider_valid "$provider"; then
        return "$EXIT_INVALID_ARGUMENT"
    fi

    if [ -z "$model" ]; then
        return "$EXIT_INVALID_ARGUMENT"
    fi

    if ! workload_valid "$workload"; then
        return "$EXIT_WORKLOAD_NOT_FOUND"
    fi

    if [ -z "$prompt" ]; then
        return "$EXIT_INVALID_ARGUMENT"
    fi

    if ! is_integer "$timeout_seconds"; then
        return "$EXIT_INVALID_ARGUMENT"
    fi

    # IMPORTANT:
    # result_create mutates the repository and must run in the
    # current shell. Capture RESULT_LAST_ID afterward.
    result_create \
        "$provider" \
        "$model" \
        "$profile" \
        "$workload" \
        "$prompt" >/dev/null || return $?

    result_id="$RESULT_LAST_ID"

    result_mark_running "$result_id" || return "$EXIT_FAILURE"

    if [ "$workload" = "$WORKLOAD_EMBEDDING" ]; then
        _executor_execute_embedding \
            "$result_id" \
            "$provider" \
            "$model" \
            "$prompt" \
            "$timeout_seconds"
    else
        _executor_execute_generation \
            "$result_id" \
            "$provider" \
            "$model" \
            "$prompt" \
            "$timeout_seconds"
    fi

    local execution_status=$?

    printf "%s\n" "$result_id"
    return "$execution_status"
}

executor_execute_workload() {
    local provider="$1"
    local model="$2"
    local profile="$3"
    local workload="$4"
    local timeout_seconds="${5-}"

    local prompt

    if ! prompt_validate "$workload"; then
        return "$EXIT_WORKLOAD_NOT_FOUND"
    fi

    prompt="$(prompt_load "$workload")" || return "$EXIT_FAILURE"

    if [ -z "$timeout_seconds" ]; then
        timeout_seconds="$(workload_timeout "$workload")"
    fi

    executor_execute_prompt \
        "$provider" \
        "$model" \
        "$profile" \
        "$workload" \
        "$prompt" \
        "$timeout_seconds"
}

executor_execute_default_generation() {
    local profile="${1:-$DEFAULT_PROFILE}"
    local workload="${2:-$WORKLOAD_REASONING}"
    local provider="${3:-$DEFAULT_PROVIDER}"

    local model

    model="$(model_preferred_generation "$provider")" || return "$EXIT_MODEL_NOT_FOUND"

    executor_execute_workload \
        "$provider" \
        "$model" \
        "$profile" \
        "$workload"
}

executor_execute_default_embedding() {
    local profile="${1:-$DEFAULT_PROFILE}"
    local provider="${2:-$DEFAULT_PROVIDER}"
    local input="${3:-Benchmark framework embedding workload.}"

    local model

    model="$(model_preferred_embedding "$provider")" || return "$EXIT_MODEL_NOT_FOUND"

    executor_execute_prompt \
        "$provider" \
        "$model" \
        "$profile" \
        "$WORKLOAD_EMBEDDING" \
        "$input" \
        "$(workload_timeout "$WORKLOAD_EMBEDDING")"
}
