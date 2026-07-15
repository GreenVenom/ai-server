#!/bin/bash

############################################################
#
# Benchmark Profile
#
# Name: Quick
#
############################################################

PROFILE_NAME="Quick"

ITERATIONS=1

PROMPTS=(
    reasoning
    coding
)

MEASURE_COLD_START=false
MEASURE_WARM_START=true
MEASURE_MEMORY=false
MEASURE_CPU=false
SAVE_JSON=true
SAVE_MARKDOWN=true
SAVE_RAW_OUTPUT=false

TIMEOUT_SECONDS=120