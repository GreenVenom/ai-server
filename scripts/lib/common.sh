#!/bin/bash

############################################################
#
# Personal AI Platform
#
# Script: common.sh
#
############################################################

divider() {
    printf '%*s\n' "${COLUMNS:-60}" '' | tr ' ' '-'
}

confirm() {
    read -rp "$1 [y/N]: " response

    [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
}

require_command() {

    if ! command -v "$1" >/dev/null 2>&1; then
        echo "Missing required command: $1"
        exit 1
    fi
}

backup_file() {

    file="$1"

    cp "$file" "${file}.bak.$(date +%s)"
}

timestamp() {
    date +"%Y-%m-%d_%H-%M-%S"
}