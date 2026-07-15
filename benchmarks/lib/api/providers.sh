#!/usr/bin/env bash
#
# ============================================================
# Personal AI Platform
# Benchmark Framework
#
# File: providers.sh
#
# Purpose:
#   Provides the stable provider-facing API used by the
#   Benchmark Framework.
#
# Responsibilities:
#   - Provider discovery
#   - Provider availability checks
#   - Provider version reporting
#   - Model enumeration
#   - Model existence checks
#   - Text generation
#   - Embedding generation
#
# Design:
#   - Provider-neutral public API
#   - Ollama is the initial concrete provider implementation
#   - Future providers may be added without changing callers
#   - Integrates with definitions.sh and errors.sh
#
# Compatibility:
#   - Bash 3.2+
#   - macOS compatible
# ============================================================

[[ -n "${BENCHMARK_PROVIDERS_LOADED:-}" ]] && return 0
BENCHMARK_PROVIDERS_LOADED=1

# ------------------------------------------------------------
# Dependency discovery
# ------------------------------------------------------------

PROVIDERS_API_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROVIDERS_LIB_DIR="$(cd "${PROVIDERS_API_DIR}/.." && pwd)"
PROVIDERS_CORE_DIR="${PROVIDERS_LIB_DIR}/core"

# shellcheck source=/dev/null
source "${PROVIDERS_CORE_DIR}/definitions.sh"

# shellcheck source=/dev/null
source "${PROVIDERS_CORE_DIR}/validators.sh"

# shellcheck source=/dev/null
source "${PROVIDERS_API_DIR}/errors.sh"

# ------------------------------------------------------------
# Provider configuration defaults
# ------------------------------------------------------------

: "${OLLAMA_HOST:=http://127.0.0.1:11434}"

# ------------------------------------------------------------
# Internal helpers
# ------------------------------------------------------------

_provider_error() {
    local function_name="$1"
    local code="$2"
    local exit_code="$3"
    local category="$4"
    local message="$5"
    local details="${6-}"
    local suggestion="${7-}"

    error_create \
        "Provider API" \
        "$function_name" \
        "$code" \
        "$exit_code" \
        "$category" \
        "$ERROR_SEVERITY_ERROR" \
        "$message" \
        "$details" \
        "$suggestion" >/dev/null
}

_provider_command_exists() {
    command -v "$1" >/dev/null 2>&1
}

_provider_http_get() {
    local url="$1"

    if ! _provider_command_exists curl; then
        return "$EXIT_FAILURE"
    fi

    curl \
        --silent \
        --show-error \
        --fail \
        --max-time 10 \
        "$url"
}

_provider_http_post_json() {
    local url="$1"
    local payload="$2"
    local timeout_seconds="${3:-$DEFAULT_TIMEOUT_SECONDS}"

    if ! _provider_command_exists curl; then
        return "$EXIT_FAILURE"
    fi

    curl \
        --silent \
        --show-error \
        --fail \
        --max-time "$timeout_seconds" \
        --header "Content-Type: application/json" \
        --data "$payload" \
        "$url"
}

_provider_json_escape() {
    local value="${1-}"

    value=${value//\\/\\\\}
    value=${value//\"/\\\"}
    value=${value//$'\n'/\\n}
    value=${value//$'\r'/\\r}
    value=${value//$'\t'/\\t}

    printf "%s" "$value"
}

# ------------------------------------------------------------
# Ollama implementation helpers
# ------------------------------------------------------------

_ollama_available() {
    _provider_http_get "${OLLAMA_HOST}/api/version" >/dev/null 2>&1
}

_ollama_version() {
    local response

    response="$(_provider_http_get "${OLLAMA_HOST}/api/version")" || return "$EXIT_FAILURE"

    if _provider_command_exists python3; then
        printf "%s" "$response" | python3 -c '
import json
import sys
data = json.load(sys.stdin)
print(data.get("version", ""))
'
        return $?
    fi

    # Fallback for simple response shape:
    # {"version":"x.y.z"}
    printf "%s\n" "$response" \
        | sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p'
}

_ollama_models() {
    local response

    response="$(_provider_http_get "${OLLAMA_HOST}/api/tags")" || return "$EXIT_FAILURE"

    if _provider_command_exists python3; then
        printf "%s" "$response" | python3 -c '
import json
import sys
data = json.load(sys.stdin)
for model in data.get("models", []):
    name = model.get("name")
    if name:
        print(name)
'
        return $?
    fi

    # Fallback parser for environments without python3.
    printf "%s\n" "$response" \
        | tr '{},' '\n' \
        | sed -n 's/.*"name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p'
}

_ollama_model_exists() {
    local target="$1"
    local model

    while IFS= read -r model; do
        [ "$model" = "$target" ] && return 0
    done <<EOF
$(_ollama_models)
EOF

    return 1
}

_ollama_generate() {
    local model="$1"
    local prompt="$2"
    local timeout_seconds="${3:-$DEFAULT_TIMEOUT_SECONDS}"

    local escaped_model
    local escaped_prompt
    local payload

    escaped_model="$(_provider_json_escape "$model")"
    escaped_prompt="$(_provider_json_escape "$prompt")"

    payload=$(
        printf '{"model":"%s","prompt":"%s","stream":false}' \
            "$escaped_model" \
            "$escaped_prompt"
    )

    _provider_http_post_json \
        "${OLLAMA_HOST}/api/generate" \
        "$payload" \
        "$timeout_seconds"
}

_ollama_embeddings() {
    local model="$1"
    local input="$2"
    local timeout_seconds="${3:-$DEFAULT_TIMEOUT_SECONDS}"

    local escaped_model
    local escaped_input
    local payload

    escaped_model="$(_provider_json_escape "$model")"
    escaped_input="$(_provider_json_escape "$input")"

    payload=$(
        printf '{"model":"%s","input":"%s"}' \
            "$escaped_model" \
            "$escaped_input"
    )

    _provider_http_post_json \
        "${OLLAMA_HOST}/api/embed" \
        "$payload" \
        "$timeout_seconds"
}

# ------------------------------------------------------------
# Public provider predicates
# ------------------------------------------------------------

provider_exists() {
    provider_valid "$1"
}

provider_available() {
    local provider="$1"

    provider_valid "$provider" || return 1

    case "$provider" in
        "$PROVIDER_OLLAMA")
            _ollama_available
            ;;
        *)
            return 1
            ;;
    esac
}

provider_model_exists() {
    local provider="$1"
    local model="$2"

    provider_valid "$provider" || return 1
    [ -n "$model" ] || return 1

    case "$provider" in
        "$PROVIDER_OLLAMA")
            _ollama_model_exists "$model"
            ;;
        *)
            return 1
            ;;
    esac
}

# ------------------------------------------------------------
# Public provider queries
# ------------------------------------------------------------

provider_version() {
    local provider="$1"

    if ! provider_valid "$provider"; then
        _provider_error \
            "provider_version" \
            "$ERR_INVALID_PROVIDER" \
            "$EXIT_INVALID_ARGUMENT" \
            "$ERROR_CATEGORY_VALIDATION" \
            "Invalid provider." \
            "Provider '${provider}' is not defined by the Benchmark Framework." \
            "Use a provider from PROVIDER_ENUM."
        return "$EXIT_INVALID_ARGUMENT"
    fi

    case "$provider" in
        "$PROVIDER_OLLAMA")
            if ! _ollama_available; then
                _provider_error \
                    "provider_version" \
                    "$ERR_PROVIDER_NOT_FOUND" \
                    "$EXIT_PROVIDER_NOT_FOUND" \
                    "$ERROR_CATEGORY_PROVIDER" \
                    "Provider is unavailable." \
                    "Ollama did not respond at ${OLLAMA_HOST}." \
                    "Verify that Ollama is running and OLLAMA_HOST is correct."
                return "$EXIT_PROVIDER_NOT_FOUND"
            fi

            _ollama_version
            ;;
        *)
            _provider_error \
                "provider_version" \
                "$ERR_PROVIDER_NOT_FOUND" \
                "$EXIT_PROVIDER_NOT_FOUND" \
                "$ERROR_CATEGORY_PROVIDER" \
                "Provider implementation is not available." \
                "Provider '${provider}' is defined but has no implementation." \
                "Use an implemented provider or add a provider adapter."
            return "$EXIT_PROVIDER_NOT_FOUND"
            ;;
    esac
}

provider_models() {
    local provider="$1"

    if ! provider_valid "$provider"; then
        _provider_error \
            "provider_models" \
            "$ERR_INVALID_PROVIDER" \
            "$EXIT_INVALID_ARGUMENT" \
            "$ERROR_CATEGORY_VALIDATION" \
            "Invalid provider." \
            "Provider '${provider}' is not defined by the Benchmark Framework." \
            "Use a provider from PROVIDER_ENUM."
        return "$EXIT_INVALID_ARGUMENT"
    fi

    case "$provider" in
        "$PROVIDER_OLLAMA")
            if ! _ollama_available; then
                _provider_error \
                    "provider_models" \
                    "$ERR_PROVIDER_NOT_FOUND" \
                    "$EXIT_PROVIDER_NOT_FOUND" \
                    "$ERROR_CATEGORY_PROVIDER" \
                    "Provider is unavailable." \
                    "Ollama did not respond at ${OLLAMA_HOST}." \
                    "Verify that Ollama is running and OLLAMA_HOST is correct."
                return "$EXIT_PROVIDER_NOT_FOUND"
            fi

            _ollama_models
            ;;
        *)
            _provider_error \
                "provider_models" \
                "$ERR_PROVIDER_NOT_FOUND" \
                "$EXIT_PROVIDER_NOT_FOUND" \
                "$ERROR_CATEGORY_PROVIDER" \
                "Provider implementation is not available." \
                "Provider '${provider}' is defined but has no implementation." \
                "Use an implemented provider or add a provider adapter."
            return "$EXIT_PROVIDER_NOT_FOUND"
            ;;
    esac
}

# ------------------------------------------------------------
# Public provider operations
# ------------------------------------------------------------

provider_generate() {
    local provider="$1"
    local model="$2"
    local prompt="$3"
    local timeout_seconds="${4:-$DEFAULT_TIMEOUT_SECONDS}"

    if ! provider_valid "$provider"; then
        _provider_error \
            "provider_generate" \
            "$ERR_INVALID_PROVIDER" \
            "$EXIT_INVALID_ARGUMENT" \
            "$ERROR_CATEGORY_VALIDATION" \
            "Invalid provider." \
            "Provider '${provider}' is not defined by the Benchmark Framework." \
            "Use a provider from PROVIDER_ENUM."
        return "$EXIT_INVALID_ARGUMENT"
    fi

    if [ -z "$model" ]; then
        _provider_error \
            "provider_generate" \
            "$ERR_INVALID_MODEL" \
            "$EXIT_INVALID_ARGUMENT" \
            "$ERROR_CATEGORY_VALIDATION" \
            "Model is required." \
            "No model identifier was supplied." \
            "Provide a valid provider-specific model name."
        return "$EXIT_INVALID_ARGUMENT"
    fi

    if [ -z "$prompt" ]; then
        _provider_error \
            "provider_generate" \
            "$ERR_INVALID_ARGUMENT" \
            "$EXIT_INVALID_ARGUMENT" \
            "$ERROR_CATEGORY_VALIDATION" \
            "Prompt is required." \
            "The generation prompt was empty." \
            "Provide a non-empty prompt."
        return "$EXIT_INVALID_ARGUMENT"
    fi

    if ! is_integer "$timeout_seconds"; then
        _provider_error \
            "provider_generate" \
            "$ERR_INVALID_ARGUMENT" \
            "$EXIT_INVALID_ARGUMENT" \
            "$ERROR_CATEGORY_VALIDATION" \
            "Timeout must be an integer." \
            "Received timeout '${timeout_seconds}'." \
            "Provide timeout seconds as a positive integer."
        return "$EXIT_INVALID_ARGUMENT"
    fi

    if ! provider_available "$provider"; then
        _provider_error \
            "provider_generate" \
            "$ERR_PROVIDER_NOT_FOUND" \
            "$EXIT_PROVIDER_NOT_FOUND" \
            "$ERROR_CATEGORY_PROVIDER" \
            "Provider is unavailable." \
            "Provider '${provider}' is not currently reachable." \
            "Start the provider and verify its configured endpoint."
        return "$EXIT_PROVIDER_NOT_FOUND"
    fi

    if ! provider_model_exists "$provider" "$model"; then
        _provider_error \
            "provider_generate" \
            "$ERR_INVALID_MODEL" \
            "$EXIT_MODEL_NOT_FOUND" \
            "$ERROR_CATEGORY_PROVIDER" \
            "Model is not available from the provider." \
            "Model '${model}' was not found in provider '${provider}'." \
            "Install the model or choose an available model."
        return "$EXIT_MODEL_NOT_FOUND"
    fi

    case "$provider" in
        "$PROVIDER_OLLAMA")
            if ! _ollama_generate "$model" "$prompt" "$timeout_seconds"; then
                _provider_error \
                    "provider_generate" \
                    "$ERR_PROVIDER_EXECUTION" \
                    "$EXIT_EXECUTION_FAILED" \
                    "$ERROR_CATEGORY_EXECUTION" \
                    "Provider generation failed." \
                    "Ollama failed to generate a response using model '${model}'." \
                    "Check provider logs, model availability, and timeout settings."
                return "$EXIT_EXECUTION_FAILED"
            fi
            ;;
        *)
            _provider_error \
                "provider_generate" \
                "$ERR_PROVIDER_NOT_FOUND" \
                "$EXIT_PROVIDER_NOT_FOUND" \
                "$ERROR_CATEGORY_PROVIDER" \
                "Provider implementation is not available." \
                "Provider '${provider}' is defined but has no generation adapter." \
                "Use an implemented provider or add a provider adapter."
            return "$EXIT_PROVIDER_NOT_FOUND"
            ;;
    esac
}

provider_embeddings() {
    local provider="$1"
    local model="$2"
    local input="$3"
    local timeout_seconds="${4:-$DEFAULT_TIMEOUT_SECONDS}"

    if ! provider_valid "$provider"; then
        _provider_error \
            "provider_embeddings" \
            "$ERR_INVALID_PROVIDER" \
            "$EXIT_INVALID_ARGUMENT" \
            "$ERROR_CATEGORY_VALIDATION" \
            "Invalid provider." \
            "Provider '${provider}' is not defined by the Benchmark Framework." \
            "Use a provider from PROVIDER_ENUM."
        return "$EXIT_INVALID_ARGUMENT"
    fi

    if [ -z "$model" ]; then
        _provider_error \
            "provider_embeddings" \
            "$ERR_INVALID_MODEL" \
            "$EXIT_INVALID_ARGUMENT" \
            "$ERROR_CATEGORY_VALIDATION" \
            "Model is required." \
            "No embedding model identifier was supplied." \
            "Provide a valid embedding model name."
        return "$EXIT_INVALID_ARGUMENT"
    fi

    if [ -z "$input" ]; then
        _provider_error \
            "provider_embeddings" \
            "$ERR_INVALID_ARGUMENT" \
            "$EXIT_INVALID_ARGUMENT" \
            "$ERROR_CATEGORY_VALIDATION" \
            "Embedding input is required." \
            "The embedding input was empty." \
            "Provide non-empty input."
        return "$EXIT_INVALID_ARGUMENT"
    fi

    if ! is_integer "$timeout_seconds"; then
        _provider_error \
            "provider_embeddings" \
            "$ERR_INVALID_ARGUMENT" \
            "$EXIT_INVALID_ARGUMENT" \
            "$ERROR_CATEGORY_VALIDATION" \
            "Timeout must be an integer." \
            "Received timeout '${timeout_seconds}'." \
            "Provide timeout seconds as a positive integer."
        return "$EXIT_INVALID_ARGUMENT"
    fi

    if ! provider_available "$provider"; then
        _provider_error \
            "provider_embeddings" \
            "$ERR_PROVIDER_NOT_FOUND" \
            "$EXIT_PROVIDER_NOT_FOUND" \
            "$ERROR_CATEGORY_PROVIDER" \
            "Provider is unavailable." \
            "Provider '${provider}' is not currently reachable." \
            "Start the provider and verify its configured endpoint."
        return "$EXIT_PROVIDER_NOT_FOUND"
    fi

    if ! provider_model_exists "$provider" "$model"; then
        _provider_error \
            "provider_embeddings" \
            "$ERR_INVALID_MODEL" \
            "$EXIT_MODEL_NOT_FOUND" \
            "$ERROR_CATEGORY_PROVIDER" \
            "Model is not available from the provider." \
            "Model '${model}' was not found in provider '${provider}'." \
            "Install the model or choose an available model."
        return "$EXIT_MODEL_NOT_FOUND"
    fi

    case "$provider" in
        "$PROVIDER_OLLAMA")
            if ! _ollama_embeddings "$model" "$input" "$timeout_seconds"; then
                _provider_error \
                    "provider_embeddings" \
                    "$ERR_PROVIDER_EXECUTION" \
                    "$EXIT_EXECUTION_FAILED" \
                    "$ERROR_CATEGORY_EXECUTION" \
                    "Provider embedding request failed." \
                    "Ollama failed to generate embeddings using model '${model}'." \
                    "Check provider logs, model capabilities, and timeout settings."
                return "$EXIT_EXECUTION_FAILED"
            fi
            ;;
        *)
            _provider_error \
                "provider_embeddings" \
                "$ERR_PROVIDER_NOT_FOUND" \
                "$EXIT_PROVIDER_NOT_FOUND" \
                "$ERROR_CATEGORY_PROVIDER" \
                "Provider implementation is not available." \
                "Provider '${provider}' is defined but has no embeddings adapter." \
                "Use an implemented provider or add a provider adapter."
            return "$EXIT_PROVIDER_NOT_FOUND"
            ;;
    esac
}
