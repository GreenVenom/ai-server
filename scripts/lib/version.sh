#!/bin/bash

############################################################
#
# Personal AI Platform
#
# Script: version.sh
#
############################################################

LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

CONFIG_FILE="${LIB_DIR}/../config/platform.conf"

if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "ERROR: Missing platform configuration."

    exit 1
fi

# shellcheck disable=SC1090
source "$CONFIG_FILE"