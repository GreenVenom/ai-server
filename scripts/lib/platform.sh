#!/bin/bash

############################################################
#
# Personal AI Platform
#
# Script: platform.sh
#
# Purpose:
# Platform and hardware information.
#
# Version: 1.0.0
#
############################################################

get_hostname() {
    hostname
}

get_macos_version() {
    sw_vers -productVersion
}

get_build_version() {
    sw_vers -buildVersion
}

get_architecture() {
    uname -m
}

get_cpu() {
    sysctl -n machdep.cpu.brand_string
}

get_memory_bytes() {
    sysctl -n hw.memsize
}

get_memory_gb() {
    local bytes
    bytes=$(get_memory_bytes)
    echo $(( bytes / 1024 / 1024 / 1024 ))
}

get_disk_free() {
    df -h "$HOME" | awk 'NR==2 {print $4}'
}

get_disk_used_percent() {
    df -h "$HOME" | awk 'NR==2 {print $5}'
}

get_uptime() {
    uptime
}

get_kernel() {
    uname -r
}