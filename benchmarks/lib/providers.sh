#!/bin/bash

############################################################
#
# Personal AI Platform
#
# Benchmark Framework
#
# Script: providers.sh
#
# Purpose:
# Provider abstraction layer.
#
# Supports multiple inference backends while exposing
# a consistent API to the Benchmark Framework.
#
# Version: 1.0.0
#
############################################################

[[ -n "${BENCHMARK_PROVIDERS_LOADED:-}" ]] && return
BENCHMARK_PROVIDERS_LOADED=1

source "$(dirname "${BASH_SOURCE[0]}")/constants.sh"

############################################################
# Active Provider
############################################################

BENCHMARK_PROVIDER="${BENCHMARK_PROVIDER:-ollama}"

provider_name() {

    echo "${BENCHMARK_PROVIDER}"

}

############################################################
# Provider Availability
############################################################

provider_available() {

    case "${BENCHMARK_PROVIDER}" in

        ollama)

            command -v ollama >/dev/null 2>&1

            ;;

        *)

            return 1

            ;;

    esac

}

############################################################
# Installed Models
############################################################

provider_models() {

    case "${BENCHMARK_PROVIDER}" in

        ollama)

            ollama list | awk 'NR>1 {print $1}'

            ;;

    esac

}

############################################################
# Model Exists
############################################################

provider_model_exists() {

    local model="$1"

    provider_models | grep -Fxq "$model"

}

############################################################
# Pull Model
############################################################

provider_pull_model() {

    local model="$1"

    case "${BENCHMARK_PROVIDER}" in

        ollama)

            ollama pull "$model"

            ;;

    esac

}

############################################################
# Remove Model
############################################################

provider_remove_model() {

    local model="$1"

    case "${BENCHMARK_PROVIDER}" in

        ollama)

            ollama rm "$model"

            ;;

    esac

}

############################################################
# Generate
############################################################

provider_generate() {

    local model="$1"

    local prompt="$2"

    case "${BENCHMARK_PROVIDER}" in

        ollama)

            ollama run "$model" "$prompt"

            ;;

    esac

}

############################################################
# Embeddings
############################################################

provider_embeddings() {

    local model="$1"

    local prompt="$2"

    case "${BENCHMARK_PROVIDER}" in

        ollama)

            ollama embed "$model" "$prompt"

            ;;

    esac

}

############################################################
# Provider Metadata
############################################################

provider_version() {

    case "${BENCHMARK_PROVIDER}" in

        ollama)

            ollama --version

            ;;

    esac

}

############################################################
# Health
############################################################

provider_health() {

    case "${BENCHMARK_PROVIDER}" in

        ollama)

            curl \
                --silent \
                --fail \
                http://127.0.0.1:11434/api/version \
                >/dev/null

            ;;

    esac

}