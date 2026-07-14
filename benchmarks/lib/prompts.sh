#!/bin/bash

############################################################
#
# Personal AI Platform
#
# Benchmark Framework
#
# Script: prompts.sh
#
# Purpose:
# Prompt discovery and workload metadata.
#
# Responsibilities:
#
#   - Prompt discovery
#   - Prompt loading
#   - Workload metadata
#   - Expected answer lookup
#   - Timeout lookup
#   - Prompt validation
#
# Version: 1.0.0
#
############################################################

[[ -n "${BENCHMARK_PROMPTS_LOADED:-}" ]] && return
BENCHMARK_PROMPTS_LOADED=1

############################################################
# Dependencies
############################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${SCRIPT_DIR}/constants.sh"
source "${SCRIPT_DIR}/common.sh"

############################################################
# Workload Registry
############################################################

supported_workloads() {

cat <<EOF
reasoning
coding
summarization
extraction
classification
creative
embedding
EOF

}

############################################################
# Prompt Discovery
############################################################

prompt_exists() {

    local workload="$1"

    [[ -f "${PROMPT_DIR}/${workload}.txt" ]]

}

list_workloads() {

    supported_workloads

}

############################################################
# Prompt Loading
############################################################

prompt_file() {

    local workload="$1"

    echo "${PROMPT_DIR}/${workload}.txt"

}

load_prompt() {

    local workload="$1"

    local file

    file=$(prompt_file "$workload")

    [[ -f "$file" ]] || return 1

    cat "$file"

}

############################################################
# Expected Results
############################################################

expected_file() {

    local workload="$1"

    echo "${EXPECTED_DIR}/${workload}.json"

}

expected_exists() {

    local workload="$1"

    [[ -f "$(expected_file "$workload")" ]]

}

############################################################
# Workload Descriptions
############################################################

workload_description() {

    case "$1" in

        reasoning)
            echo "General reasoning and analytical capability"
            ;;

        coding)
            echo "Code generation"
            ;;

        summarization)
            echo "Summarization"
            ;;

        extraction)
            echo "Structured data extraction"
            ;;

        classification)
            echo "Classification"
            ;;

        creative)
            echo "Creative writing"
            ;;

        embedding)
            echo "Embedding generation"
            ;;

        *)
            echo "Unknown"
            ;;
    esac

}

############################################################
# Timeout
############################################################

workload_timeout() {

    case "$1" in

        reasoning)

            echo 180

            ;;

        coding)

            echo 180

            ;;

        summarization)

            echo 120

            ;;

        extraction)

            echo 60

            ;;

        classification)

            echo 60

            ;;

        creative)

            echo 300

            ;;

        embedding)

            echo 60

            ;;

        *)

            echo "${DEFAULT_TIMEOUT}"

            ;;

    esac

}

############################################################
# Scoring
############################################################

workload_is_scored() {

    case "$1" in

        extraction|classification|reasoning)

            return 0

            ;;

        *)

            return 1

            ;;

    esac

}

############################################################
# Validation
############################################################

validate_workload() {

    local workload="$1"

    supported_workloads | grep -Fxq "$workload"

}

############################################################
# Summary
############################################################

print_workloads() {

    echo

    printf "%-18s %-10s %s\n" \
        "Workload" \
        "Scored" \
        "Description"

    printf "%-18s %-10s %s\n" \
        "--------" \
        "-------" \
        "-----------"

    while read -r workload
    do

        if workload_is_scored "$workload"
        then
            scored="Yes"
        else
            scored="No"
        fi

        printf "%-18s %-10s %s\n" \
            "$workload" \
            "$scored" \
            "$(workload_description "$workload")"

    done < <(supported_workloads)

}