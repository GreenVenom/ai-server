#!/bin/bash

############################################################
#
# Personal AI Platform
#
# Benchmark Framework
#
# Script: constants.sh
#
# Purpose:
# Shared constants used throughout the Benchmark Framework.
#
# This file intentionally contains no executable logic.
#
# Version: 1.0.0
#
############################################################

#
# Prevent multiple inclusion
#

[[ -n "${BENCHMARK_CONSTANTS_LOADED:-}" ]] && return
BENCHMARK_CONSTANTS_LOADED=1

############################################################
# Framework Metadata
############################################################

BENCHMARK_FRAMEWORK_NAME="Benchmark Framework"

BENCHMARK_FRAMEWORK_VERSION="1.0.0"

############################################################
# Directory Names
############################################################

LIB_DIRECTORY_NAME="lib"

PROFILE_DIRECTORY_NAME="profiles"

PROMPT_DIRECTORY_NAME="prompts"

EXPECTED_DIRECTORY_NAME="expected"

RESULT_DIRECTORY_NAME="results"

REPORT_DIRECTORY_NAME="reports"

############################################################
# Default Benchmark Settings
############################################################

DEFAULT_PROFILE="standard"

DEFAULT_ITERATIONS=3

DEFAULT_TIMEOUT=120

DEFAULT_OUTPUT_FORMAT="json"

############################################################
# Supported Output Formats
############################################################

FORMAT_JSON="json"

FORMAT_MARKDOWN="markdown"

FORMAT_TEXT="text"

############################################################
# Benchmark Workloads
############################################################

WORKLOAD_REASONING="reasoning"

WORKLOAD_CODING="coding"

WORKLOAD_SUMMARIZATION="summarization"

WORKLOAD_EXTRACTION="extraction"

WORKLOAD_CLASSIFICATION="classification"

WORKLOAD_CREATIVE="creative"

WORKLOAD_EMBEDDING="embedding"

############################################################
# Result Status
############################################################

STATUS_PASS="PASS"

STATUS_WARN="WARN"

STATUS_FAIL="FAIL"

############################################################
# Severity
############################################################

SEVERITY_INFO="INFO"

SEVERITY_LOW="LOW"

SEVERITY_MEDIUM="MEDIUM"

SEVERITY_HIGH="HIGH"

SEVERITY_CRITICAL="CRITICAL"

############################################################
# Exit Codes
############################################################

EXIT_SUCCESS=0

EXIT_FAILURE=1

EXIT_INVALID_ARGUMENT=2

EXIT_PROFILE_NOT_FOUND=3

EXIT_MODEL_NOT_FOUND=4

EXIT_PROMPT_NOT_FOUND=5

EXIT_BENCHMARK_FAILED=10

############################################################
# Ollama Defaults
############################################################

DEFAULT_OLLAMA_HOST="127.0.0.1:11434"

DEFAULT_API_VERSION_ENDPOINT="/api/version"

DEFAULT_GENERATE_ENDPOINT="/api/generate"

DEFAULT_EMBED_ENDPOINT="/api/embed"

############################################################
# Report Titles
############################################################

REPORT_TITLE="Benchmark Report"

SUMMARY_TITLE="Benchmark Summary"

############################################################
# Timestamp Formats
############################################################

DATE_FORMAT="%Y-%m-%d"

TIMESTAMP_FORMAT="%Y-%m-%d_%H-%M-%S"

############################################################
# JSON Keys
############################################################

JSON_MODEL="model"

JSON_PROFILE="profile"

JSON_PROMPT="prompt"

JSON_ITERATION="iteration"

JSON_DURATION="duration"

JSON_TOKENS_PER_SECOND="tokens_per_second"

JSON_MEMORY_MB="memory_mb"

JSON_CPU_PERCENT="cpu_percent"

JSON_TIMESTAMP="timestamp"

############################################################
# Miscellaneous
############################################################

HORIZONTAL_RULE="------------------------------------------------------------"

DEFAULT_COLUMN_WIDTH=80