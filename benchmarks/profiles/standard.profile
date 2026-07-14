#!/bin/bash

############################################################
#
# Benchmark Profile
#
# Name: Standard
#
############################################################

PROFILE_NAME="Standard"

ITERATIONS=3

PROMPTS=(
    reasoning
    coding
    summarization
    extraction
    classification
)

MEASURE_COLD_START=true
MEASURE_WARM_START=true
MEASURE_MEMORY=true
MEASURE_CPU=true
SAVE_JSON=true
SAVE_MARKDOWN=true
SAVE_RAW_OUTPUT=false

TIMEOUT_SECONDS=120