#!/bin/bash

############################################################
#
# Personal AI Platform
#
# Script: colors.sh
#
# Purpose:
# Provides standardized terminal colors and formatting.
#
# Version: 1.0.0
# Platform Version: v0.2.0
#
############################################################

if [[ -t 1 ]]; then
    RED="\033[0;31m"
    GREEN="\033[0;32m"
    YELLOW="\033[1;33m"
    BLUE="\033[0;34m"
    MAGENTA="\033[0;35m"
    CYAN="\033[0;36m"
    BOLD="\033[1m"
    RESET="\033[0m"
else
    RED=""
    GREEN=""
    YELLOW=""
    BLUE=""
    MAGENTA=""
    CYAN=""
    BOLD=""
    RESET=""
fi

print_header() {
    echo
    echo -e "${BOLD}${BLUE}============================================================${RESET}"
    echo -e "${BOLD}${BLUE}$1${RESET}"
    echo -e "${BOLD}${BLUE}============================================================${RESET}"
}

print_section() {
    echo
    echo -e "${CYAN}▶ $1${RESET}"
}

print_success() {
    echo -e "${GREEN}✔ $1${RESET}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${RESET}"
}

print_error() {
    echo -e "${RED}✖ $1${RESET}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${RESET}"
}