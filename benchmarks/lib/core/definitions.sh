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
# This file intentionally contains NO implementation logic.
# It is the authoritative definition of:
#
#   • Framework metadata
#   • Enumerations
#   • Result schema
#   • Field types
#   • Required fields
#   • Defaults
#   • Output formats
#   • Exit codes
#
# Every library in the Benchmark Framework consumes this
# specification.
# ============================================================

[[ -n "${BENCHMARK_DEFINITIONS_LOADED:-}" ]] && return
readonly BENCHMARK_DEFINITIONS_LOADED=1

############################################################
# Framework
############################################################

readonly BENCHMARK_FRAMEWORK_NAME="Benchmark Framework"

readonly BENCHMARK_SCHEMA_VERSION="2.0"

############################################################
# Repository
############################################################

readonly RESULT_REPOSITORY_VERSION="2"

readonly RESULT_ID_PREFIX="result"

readonly RESULT_TIMESTAMP_FORMAT="%Y-%m-%dT%H:%M:%SZ"

############################################################
# Providers
############################################################

readonly PROVIDER_OLLAMA="ollama"
readonly PROVIDER_LM_STUDIO="lmstudio"
readonly PROVIDER_VLLM="vllm"
readonly PROVIDER_LLAMACPP="llamacpp"
readonly PROVIDER_OPENAI="openai"
readonly PROVIDER_CLAUDE="claude"
readonly PROVIDER_OPENROUTER="openrouter"

declare -agr PROVIDER_ENUM=(

    "$PROVIDER_OLLAMA"
    "$PROVIDER_LM_STUDIO"
    "$PROVIDER_VLLM"
    "$PROVIDER_LLAMACPP"
    "$PROVIDER_OPENAI"
    "$PROVIDER_CLAUDE"
    "$PROVIDER_OPENROUTER"

)

############################################################
# Provider Capabilities
############################################################

readonly CAPABILITY_TEXT="text"
readonly CAPABILITY_EMBEDDINGS="embeddings"
readonly CAPABILITY_VISION="vision"
readonly CAPABILITY_TOOLS="tools"
readonly CAPABILITY_FUNCTIONS="functions"
readonly CAPABILITY_AUDIO="audio"
readonly CAPABILITY_SPEECH="speech"

declare -agr CAPABILITY_ENUM=(

    "$CAPABILITY_TEXT"
    "$CAPABILITY_EMBEDDINGS"
    "$CAPABILITY_VISION"
    "$CAPABILITY_TOOLS"
    "$CAPABILITY_FUNCTIONS"
    "$CAPABILITY_AUDIO"
    "$CAPABILITY_SPEECH"

)

############################################################
# Workloads
############################################################

readonly WORKLOAD_REASONING="reasoning"
readonly WORKLOAD_CODING="coding"
readonly WORKLOAD_SUMMARIZATION="summarization"
readonly WORKLOAD_EXTRACTION="extraction"
readonly WORKLOAD_CLASSIFICATION="classification"
readonly WORKLOAD_CREATIVE="creative"
readonly WORKLOAD_EMBEDDING="embedding"

declare -agr WORKLOAD_ENUM=(

    "$WORKLOAD_REASONING"
    "$WORKLOAD_CODING"
    "$WORKLOAD_SUMMARIZATION"
    "$WORKLOAD_EXTRACTION"
    "$WORKLOAD_CLASSIFICATION"
    "$WORKLOAD_CREATIVE"
    "$WORKLOAD_EMBEDDING"

)

############################################################
# Result Lifecycle
############################################################

readonly RESULT_STATUS_CREATED="created"
readonly RESULT_STATUS_RUNNING="running"
readonly RESULT_STATUS_COMPLETED="completed"
readonly RESULT_STATUS_FAILED="failed"
readonly RESULT_STATUS_SKIPPED="skipped"
readonly RESULT_STATUS_TIMEOUT="timeout"
readonly RESULT_STATUS_CANCELLED="cancelled"

declare -agr RESULT_STATUS_ENUM=(

    "$RESULT_STATUS_CREATED"
    "$RESULT_STATUS_RUNNING"
    "$RESULT_STATUS_COMPLETED"
    "$RESULT_STATUS_FAILED"
    "$RESULT_STATUS_SKIPPED"
    "$RESULT_STATUS_TIMEOUT"
    "$RESULT_STATUS_CANCELLED"

)

############################################################
# Result Fields
############################################################

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

declare -agr RESULT_FIELD_ENUM=(

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

############################################################
# Field Types
############################################################

declare -Agr RESULT_FIELD_TYPES=(

    ["id"]="string"
    ["created"]="datetime"
    ["timestamp"]="datetime"

    ["status"]="enum"

    ["provider"]="string"
    ["model"]="string"
    ["profile"]="string"

    ["workload"]="string"
    ["prompt"]="string"

    ["duration_ms"]="integer"
    ["duration_seconds"]="float"

    ["tokens"]="integer"
    ["tokens_per_second"]="float"

    ["memory_mb"]="integer"
    ["cpu_percent"]="float"

    ["exit_code"]="integer"
    ["error"]="string"

    ["output"]="string"

)

############################################################
# Required Fields
############################################################

declare -Agr RESULT_FIELD_REQUIRED=(

    ["id"]="true"
    ["created"]="true"
    ["status"]="true"

    ["provider"]="true"
    ["model"]="true"

)

############################################################
# Defaults
############################################################

readonly DEFAULT_PROVIDER="$PROVIDER_OLLAMA"

readonly DEFAULT_PROFILE="standard"

readonly DEFAULT_ITERATIONS=3

readonly DEFAULT_TIMEOUT_SECONDS=120

readonly DEFAULT_RESULT_STATUS="$RESULT_STATUS_CREATED"

############################################################
# Output Formats
############################################################

readonly FORMAT_TEXT="text"
readonly FORMAT_JSON="json"
readonly FORMAT_MARKDOWN="markdown"
readonly FORMAT_CSV="csv"

declare -agr OUTPUT_FORMAT_ENUM=(

    "$FORMAT_TEXT"
    "$FORMAT_JSON"
    "$FORMAT_MARKDOWN"
    "$FORMAT_CSV"

)

############################################################
# Exit Codes
############################################################

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

############################################################
# Error Categories
############################################################

readonly ERROR_CATEGORY_VALIDATION="validation"
readonly ERROR_CATEGORY_CONFIGURATION="configuration"
readonly ERROR_CATEGORY_EXECUTION="execution"
readonly ERROR_CATEGORY_FILESYSTEM="filesystem"
readonly ERROR_CATEGORY_NETWORK="network"
readonly ERROR_CATEGORY_PROVIDER="provider"
readonly ERROR_CATEGORY_SERIALIZATION="serialization"
readonly ERROR_CATEGORY_INTERNAL="internal"

declare -agr ERROR_CATEGORY_ENUM=(

    "$ERROR_CATEGORY_VALIDATION"
    "$ERROR_CATEGORY_CONFIGURATION"
    "$ERROR_CATEGORY_EXECUTION"
    "$ERROR_CATEGORY_FILESYSTEM"
    "$ERROR_CATEGORY_NETWORK"
    "$ERROR_CATEGORY_PROVIDER"
    "$ERROR_CATEGORY_SERIALIZATION"
    "$ERROR_CATEGORY_INTERNAL"

)

############################################################
# Error Severities
############################################################

readonly ERROR_SEVERITY_INFO="info"
readonly ERROR_SEVERITY_WARNING="warning"
readonly ERROR_SEVERITY_ERROR="error"
readonly ERROR_SEVERITY_FATAL="fatal"

declare -agr ERROR_SEVERITY_ENUM=(

    "$ERROR_SEVERITY_INFO"
    "$ERROR_SEVERITY_WARNING"
    "$ERROR_SEVERITY_ERROR"
    "$ERROR_SEVERITY_FATAL"

)

############################################################
# Error Fields
############################################################

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

declare -agr ERROR_FIELD_ENUM=(

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

############################################################
# Error Codes
############################################################

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