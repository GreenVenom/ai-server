#!/bin/bash

############################################################
#
# Personal AI Platform
#
# Benchmark Framework
#
# Script: common.sh
#
# Purpose:
# Shared utility functions for the Benchmark Framework.
#
# Responsibilities:
#   - Repository discovery
#   - Directory initialization
#   - Profile loading
#   - Prompt loading
#   - Timestamp generation
#   - Argument validation
#   - File validation
#
# Version: 1.0.0
#
############################################################

#
# Prevent multiple inclusion
#

[[ -n "${BENCHMARK_COMMON_LOADED:-}" ]] && return
BENCHMARK_COMMON_LOADED=1

############################################################
# Repository Discovery
############################################################

COMMON_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

BENCHMARK_ROOT="$(cd "${COMMON_DIR}/.." && pwd)"

REPOSITORY_ROOT="$(cd "${BENCHMARK_ROOT}/.." && pwd)"

############################################################
# Directory Layout
############################################################

LIB_DIR="${BENCHMARK_ROOT}/lib"

PROFILE_DIR="${BENCHMARK_ROOT}/profiles"

PROMPT_DIR="${BENCHMARK_ROOT}/prompts"

EXPECTED_DIR="${BENCHMARK_ROOT}/expected"

RESULTS_DIR="${BENCHMARK_ROOT}/results"

REPORTS_DIR="${BENCHMARK_ROOT}/reports"

############################################################
# Timestamp
############################################################

benchmark_timestamp() {

    date +"%Y-%m-%d_%H-%M-%S"

}

benchmark_date() {

    date +"%Y-%m-%d"

}

benchmark_epoch() {

    date +%s

}

############################################################
# Repository Information
############################################################

repository_name() {

    basename "${REPOSITORY_ROOT}"

}

repository_root() {

    echo "${REPOSITORY_ROOT}"

}

benchmark_root() {

    echo "${BENCHMARK_ROOT}"

}

############################################################
# Directory Initialization
############################################################

initialize_directories() {

    mkdir -p "${RESULTS_DIR}"

    mkdir -p "${REPORTS_DIR}"

    mkdir -p "${EXPECTED_DIR}"

}

############################################################
# Profile Loading
############################################################

profile_exists() {

    [[ -f "${PROFILE_DIR}/$1.profile" ]]

}

load_profile() {

    local profile="$1"

    local file="${PROFILE_DIR}/${profile}.profile"

    if [[ ! -f "${file}" ]]; then

        echo "Benchmark profile not found: ${profile}"

        return 1

    fi

    # shellcheck source=/dev/null
    source "${file}"

}

list_profiles() {

    find "${PROFILE_DIR}" \
        -maxdepth 1 \
        -name "*.profile" \
        -print |
        sed 's|.*/||' |
        sed 's|\.profile$||' |
        sort

}

############################################################
# Prompt Loading
############################################################

prompt_exists() {

    [[ -f "${PROMPT_DIR}/$1.txt" ]]

}

load_prompt() {

    local prompt="$1"

    local file="${PROMPT_DIR}/${prompt}.txt"

    if [[ ! -f "${file}" ]]; then

        echo "Prompt not found: ${prompt}"

        return 1

    fi

    cat "${file}"

}

list_prompts() {

    find "${PROMPT_DIR}" \
        -maxdepth 1 \
        -name "*.txt" \
        -print |
        sed 's|.*/||' |
        sed 's|\.txt$||' |
        sort

}

############################################################
# Expected Results
############################################################

expected_exists() {

    [[ -f "${EXPECTED_DIR}/$1" ]]

}

############################################################
# Validation
############################################################

require_file() {

    local file="$1"

    if [[ ! -f "${file}" ]]; then

        echo "Required file missing: ${file}"

        return 1

    fi

}

require_directory() {

    local directory="$1"

    if [[ ! -d "${directory}" ]]; then

        echo "Required directory missing: ${directory}"

        return 1

    fi

}

############################################################
# Result Directories
############################################################

result_directory() {

    local ts

    ts="$(benchmark_timestamp)"

    local dir="${RESULTS_DIR}/${ts}"

    mkdir -p "${dir}"

    echo "${dir}"

}

report_directory() {

    local ts

    ts="$(benchmark_timestamp)"

    local dir="${REPORTS_DIR}/${ts}"

    mkdir -p "${dir}"

    echo "${dir}"

}

############################################################
# Filename Helpers
############################################################

json_filename() {

    local model="$1"

    echo "${model}.json"

}

markdown_filename() {

    local model="$1"

    echo "${model}.md"

}

############################################################
# Utility
############################################################

divider() {

    printf '%*s\n' "${COLUMNS:-80}" '' | tr ' ' '-'

}

center_text() {

    local width="${COLUMNS:-80}"

    printf "%*s\n" $(((${#1}+width)/2)) "$1"

}

############################################################
# Framework Information
############################################################

benchmark_framework_version() {

    echo "1.0.0"

}

framework_banner() {

    divider

    center_text "Personal AI Platform"

    center_text "Benchmark Framework"

    center_text "Version $(benchmark_framework_version)"

    divider

}