#!/usr/bin/env bash
#
# ============================================================
# Personal AI Platform
# Benchmark Framework
#
# File: definitions.sh
#
# Purpose:
#   Defines the Benchmark Framework specification.
#
# Responsibilities:
#   - Framework metadata
#   - Provider definitions
#   - Capability definitions
#   - Workload definitions
#   - Result schema
#   - Error schema
#   - Output formats
#   - Exit codes
#
# Compatibility:
#   - Bash 3.2+
#   - No associative arrays
#   - No declare -g
# ============================================================

[[ -n "${BENCHMARK_DEFINITIONS_LOADED:-}" ]] && return 0
BENCHMARK_DEFINITIONS_LOADED=1

# ------------------------------------------------------------
# Framework metadata
# ------------------------------------------------------------

readonly BENCHMARK_FRAMEWORK_NAME="Benchmark Framework"
readonly BENCHMARK_SCHEMA_VERSION="2.0"

# ------------------------------------------------------------
# Repository metadata
# ------------------------------------------------------------

readonly RESULT_REPOSITORY_VERSION="2"
readonly RESULT_ID_PREFIX="result"
readonly RESULT_TIMESTAMP_FORMAT="%Y-%m-%dT%H:%M:%SZ"

# ------------------------------------------------------------
# Providers
# ------------------------------------------------------------

readonly PROVIDER_OLLAMA="ollama"
readonly PROVIDER_LMSTUDIO="lmstudio"
readonly PROVIDER_VLLM="vllm"
readonly PROVIDER_LLAMACPP="llamacpp"
readonly PROVIDER_OPENAI="openai"
readonly PROVIDER_CLAUDE="claude"
readonly PROVIDER_OPENROUTER="openrouter"

PROVIDER_ENUM=(
    "$PROVIDER_OLLAMA"
    "$PROVIDER_LMSTUDIO"
    "$PROVIDER_VLLM"
    "$PROVIDER_LLAMACPP"
    "$PROVIDER_OPENAI"
    "$PROVIDER_CLAUDE"
    "$PROVIDER_OPENROUTER"
)

# ------------------------------------------------------------
# Capabilities
# ------------------------------------------------------------

readonly CAPABILITY_TEXT="text"
readonly CAPABILITY_EMBEDDINGS="embeddings"
readonly CAPABILITY_VISION="vision"
readonly CAPABILITY_TOOLS="tools"
readonly CAPABILITY_FUNCTIONS="functions"
readonly CAPABILITY_AUDIO="audio"
readonly CAPABILITY_SPEECH="speech"

CAPABILITY_ENUM=(
    "$CAPABILITY_TEXT"
    "$CAPABILITY_EMBEDDINGS"
    "$CAPABILITY_VISION"
    "$CAPABILITY_TOOLS"
    "$CAPABILITY_FUNCTIONS"
    "$CAPABILITY_AUDIO"
    "$CAPABILITY_SPEECH"
)

# ------------------------------------------------------------
# Workloads
# ------------------------------------------------------------

readonly WORKLOAD_REASONING="reasoning"
readonly WORKLOAD_CODING="coding"
readonly WORKLOAD_SUMMARIZATION="summarization"
readonly WORKLOAD_EXTRACTION="extraction"
readonly WORKLOAD_CLASSIFICATION="classification"
readonly WORKLOAD_CREATIVE="creative"
readonly WORKLOAD_EMBEDDING="embedding"

WORKLOAD_ENUM=(
    "$WORKLOAD_REASONING"
    "$WORKLOAD_CODING"
    "$WORKLOAD_SUMMARIZATION"
    "$WORKLOAD_EXTRACTION"
    "$WORKLOAD_CLASSIFICATION"
    "$WORKLOAD_CREATIVE"
    "$WORKLOAD_EMBEDDING"
)

# ------------------------------------------------------------
# Result lifecycle
# ------------------------------------------------------------

readonly RESULT_STATUS_CREATED="created"
readonly RESULT_STATUS_RUNNING="running"
readonly RESULT_STATUS_COMPLETED="completed"
readonly RESULT_STATUS_FAILED="failed"
readonly RESULT_STATUS_SKIPPED="skipped"
readonly RESULT_STATUS_TIMEOUT="timeout"
readonly RESULT_STATUS_CANCELLED="cancelled"

RESULT_STATUS_ENUM=(
    "$RESULT_STATUS_CREATED"
    "$RESULT_STATUS_RUNNING"
    "$RESULT_STATUS_COMPLETED"
    "$RESULT_STATUS_FAILED"
    "$RESULT_STATUS_SKIPPED"
    "$RESULT_STATUS_TIMEOUT"
    "$RESULT_STATUS_CANCELLED"
)

# ------------------------------------------------------------
# Result fields
# ------------------------------------------------------------

readonly RESULT_FIELD_ID="id"
readonly RESULT_FIELD_CREATED="created"
readonly RESULT_FIELD_TIMESTAMP="timestamp"
readonly RESULT_FIELD_STATUS="status"
readonly RESULT_FIELD_PROVIDER="provider"
readonly RESULT_FIELD_MODEL="model"
readonly RESULT_FIELD_PROFILE="profile"
readonly RESULT_FIELD_WORKLOAD="workload"
readonly RESULT_FIELD_PROMPT="prompt"
readonly RESULT_FIELD_DURATION_MS="duration_ms"
readonly RESULT_FIELD_DURATION_SECONDS="duration_seconds"
readonly RESULT_FIELD_TOKENS="tokens"
readonly RESULT_FIELD_TOKENS_PER_SECOND="tokens_per_second"
readonly RESULT_FIELD_MEMORY_MB="memory_mb"
readonly RESULT_FIELD_CPU_PERCENT="cpu_percent"
readonly RESULT_FIELD_EXIT_CODE="exit_code"
readonly RESULT_FIELD_ERROR="error"
readonly RESULT_FIELD_OUTPUT="output"

RESULT_FIELD_ENUM=(
    "$RESULT_FIELD_ID"
    "$RESULT_FIELD_CREATED"
    "$RESULT_FIELD_TIMESTAMP"
    "$RESULT_FIELD_STATUS"
    "$RESULT_FIELD_PROVIDER"
    "$RESULT_FIELD_MODEL"
    "$RESULT_FIELD_PROFILE"
    "$RESULT_FIELD_WORKLOAD"
    "$RESULT_FIELD_PROMPT"
    "$RESULT_FIELD_DURATION_MS"
    "$RESULT_FIELD_DURATION_SECONDS"
    "$RESULT_FIELD_TOKENS"
    "$RESULT_FIELD_TOKENS_PER_SECOND"
    "$RESULT_FIELD_MEMORY_MB"
    "$RESULT_FIELD_CPU_PERCENT"
    "$RESULT_FIELD_EXIT_CODE"
    "$RESULT_FIELD_ERROR"
    "$RESULT_FIELD_OUTPUT"
)

# Parallel arrays provide Bash 3.2-compatible schema lookup.

RESULT_FIELD_TYPE_FIELDS=(
    "$RESULT_FIELD_ID"
    "$RESULT_FIELD_CREATED"
    "$RESULT_FIELD_TIMESTAMP"
    "$RESULT_FIELD_STATUS"
    "$RESULT_FIELD_PROVIDER"
    "$RESULT_FIELD_MODEL"
    "$RESULT_FIELD_PROFILE"
    "$RESULT_FIELD_WORKLOAD"
    "$RESULT_FIELD_PROMPT"
    "$RESULT_FIELD_DURATION_MS"
    "$RESULT_FIELD_DURATION_SECONDS"
    "$RESULT_FIELD_TOKENS"
    "$RESULT_FIELD_TOKENS_PER_SECOND"
    "$RESULT_FIELD_MEMORY_MB"
    "$RESULT_FIELD_CPU_PERCENT"
    "$RESULT_FIELD_EXIT_CODE"
    "$RESULT_FIELD_ERROR"
    "$RESULT_FIELD_OUTPUT"
)

RESULT_FIELD_TYPE_VALUES=(
    "string"
    "datetime"
    "datetime"
    "enum"
    "string"
    "string"
    "string"
    "string"
    "string"
    "integer"
    "float"
    "integer"
    "float"
    "integer"
    "float"
    "integer"
    "string"
    "string"
)

RESULT_FIELD_REQUIRED_FIELDS=(
    "$RESULT_FIELD_ID"
    "$RESULT_FIELD_CREATED"
    "$RESULT_FIELD_STATUS"
    "$RESULT_FIELD_PROVIDER"
    "$RESULT_FIELD_MODEL"
)

# ------------------------------------------------------------
# Defaults
# ------------------------------------------------------------

readonly DEFAULT_PROVIDER="$PROVIDER_OLLAMA"
readonly DEFAULT_PROFILE="standard"
readonly DEFAULT_ITERATIONS=3
readonly DEFAULT_TIMEOUT_SECONDS=120
readonly DEFAULT_RESULT_STATUS="$RESULT_STATUS_CREATED"

# ------------------------------------------------------------
# Output formats
# ------------------------------------------------------------

readonly OUTPUT_FORMAT_TEXT="text"
readonly OUTPUT_FORMAT_JSON="json"
readonly OUTPUT_FORMAT_MARKDOWN="markdown"
readonly OUTPUT_FORMAT_CSV="csv"

OUTPUT_FORMAT_ENUM=(
    "$OUTPUT_FORMAT_TEXT"
    "$OUTPUT_FORMAT_JSON"
    "$OUTPUT_FORMAT_MARKDOWN"
    "$OUTPUT_FORMAT_CSV"
)

# ------------------------------------------------------------
# Exit codes
# ------------------------------------------------------------

readonly EXIT_SUCCESS=0
readonly EXIT_FAILURE=1
readonly EXIT_INVALID_ARGUMENT=2
readonly EXIT_INVALID_STATE=3
readonly EXIT_PROVIDER_NOT_FOUND=10
readonly EXIT_MODEL_NOT_FOUND=11
readonly EXIT_WORKLOAD_NOT_FOUND=12
readonly EXIT_TIMEOUT=20
readonly EXIT_EXECUTION_FAILED=30
readonly EXIT_SERIALIZATION_FAILED=40

# ------------------------------------------------------------
# Error categories
# ------------------------------------------------------------

readonly ERROR_CATEGORY_VALIDATION="validation"
readonly ERROR_CATEGORY_CONFIGURATION="configuration"
readonly ERROR_CATEGORY_EXECUTION="execution"
readonly ERROR_CATEGORY_FILESYSTEM="filesystem"
readonly ERROR_CATEGORY_NETWORK="network"
readonly ERROR_CATEGORY_PROVIDER="provider"
readonly ERROR_CATEGORY_SERIALIZATION="serialization"
readonly ERROR_CATEGORY_INTERNAL="internal"

ERROR_CATEGORY_ENUM=(
    "$ERROR_CATEGORY_VALIDATION"
    "$ERROR_CATEGORY_CONFIGURATION"
    "$ERROR_CATEGORY_EXECUTION"
    "$ERROR_CATEGORY_FILESYSTEM"
    "$ERROR_CATEGORY_NETWORK"
    "$ERROR_CATEGORY_PROVIDER"
    "$ERROR_CATEGORY_SERIALIZATION"
    "$ERROR_CATEGORY_INTERNAL"
)

# ------------------------------------------------------------
# Error severities
# ------------------------------------------------------------

readonly ERROR_SEVERITY_INFO="info"
readonly ERROR_SEVERITY_WARNING="warning"
readonly ERROR_SEVERITY_ERROR="error"
readonly ERROR_SEVERITY_FATAL="fatal"

ERROR_SEVERITY_ENUM=(
    "$ERROR_SEVERITY_INFO"
    "$ERROR_SEVERITY_WARNING"
    "$ERROR_SEVERITY_ERROR"
    "$ERROR_SEVERITY_FATAL"
)

# ------------------------------------------------------------
# Error fields
# ------------------------------------------------------------

readonly ERROR_FIELD_TIMESTAMP="timestamp"
readonly ERROR_FIELD_COMPONENT="component"
readonly ERROR_FIELD_FUNCTION="function"
readonly ERROR_FIELD_CODE="code"
readonly ERROR_FIELD_EXIT_CODE="exit_code"
readonly ERROR_FIELD_CATEGORY="category"
readonly ERROR_FIELD_SEVERITY="severity"
readonly ERROR_FIELD_MESSAGE="message"
readonly ERROR_FIELD_DETAILS="details"
readonly ERROR_FIELD_SUGGESTION="suggestion"

ERROR_FIELD_ENUM=(
    "$ERROR_FIELD_TIMESTAMP"
    "$ERROR_FIELD_COMPONENT"
    "$ERROR_FIELD_FUNCTION"
    "$ERROR_FIELD_CODE"
    "$ERROR_FIELD_EXIT_CODE"
    "$ERROR_FIELD_CATEGORY"
    "$ERROR_FIELD_SEVERITY"
    "$ERROR_FIELD_MESSAGE"
    "$ERROR_FIELD_DETAILS"
    "$ERROR_FIELD_SUGGESTION"
)

# ------------------------------------------------------------
# Symbolic error codes
# ------------------------------------------------------------

readonly ERR_SUCCESS=0

readonly ERR_INVALID_ARGUMENT=1000
readonly ERR_INVALID_PROVIDER=1001
readonly ERR_INVALID_MODEL=1002
readonly ERR_INVALID_WORKLOAD=1003
readonly ERR_INVALID_RESULT=1004

readonly ERR_CONFIGURATION=2000

readonly ERR_PROVIDER_NOT_FOUND=3000
readonly ERR_PROVIDER_EXECUTION=3001

readonly ERR_SERIALIZATION=4000

readonly ERR_INTERNAL=9000

# ------------------------------------------------------------
# Specification lookup helpers
# ------------------------------------------------------------

definition_array_contains() {
    local needle="$1"
    shift

    local item
    for item in "$@"; do
        [ "$item" = "$needle" ] && return 0
    done

    return 1
}

result_field_type_lookup() {
    local field="$1"
    local i=0

    while [ "$i" -lt "${#RESULT_FIELD_TYPE_FIELDS[@]}" ]; do
        if [ "${RESULT_FIELD_TYPE_FIELDS[$i]}" = "$field" ]; then
            printf "%s\n" "${RESULT_FIELD_TYPE_VALUES[$i]}"
            return 0
        fi
        i=$((i + 1))
    done

    return 1
}

result_field_required_lookup() {
    local field="$1"

    if definition_array_contains "$field" "${RESULT_FIELD_REQUIRED_FIELDS[@]}"; then
        printf "true\n"
    else
        printf "false\n"
    fi

    return 0
}
