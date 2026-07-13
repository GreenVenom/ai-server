#!/bin/bash

############################################################
#
# Personal AI Platform
#
# Script: checks.sh
#
# Purpose:
# Standardized platform validation framework.
#
# Version: 2.0.0
#
############################################################

############################################################
# Execute Check
############################################################

execute_check() {

    "$@"

    ((CHECK_COUNT++))

    case "$RESULT_STATUS" in

        PASS)

            ((PASS_COUNT++))
            print_success "$RESULT_COMPONENT"
            ;;

        WARN)

            ((WARN_COUNT++))
            print_warning "$RESULT_COMPONENT"
            ;;

        FAIL)

            ((FAIL_COUNT++))
            print_error "$RESULT_COMPONENT"
            ;;

        *)

            ((FAIL_COUNT++))

            RESULT_STATUS="FAIL"
            RESULT_COMPONENT="Framework"
            RESULT_MESSAGE="Unknown check result"
            RESULT_SEVERITY="$SEVERITY_CRITICAL"

            print_error "Framework"

            ;;

    esac

    printf "    %s\n" "$RESULT_MESSAGE"

    log_info "$RESULT_STATUS [$RESULT_SEVERITY] $RESULT_COMPONENT - $RESULT_MESSAGE"
}

############################################################
# Directory
############################################################

check_directory() {

    local component="$1"
    local directory="$2"

    reset_result

    if [[ -d "$directory" ]]; then

        pass "$component" "Directory exists"

        return 0

    fi

    fail "$component" "Directory not found: $directory"

    return 1
}

############################################################
# File
############################################################

check_file() {

    local component="$1"
    local file="$2"

    reset_result

    if [[ -f "$file" ]]; then

        pass "$component" "File exists"

        return 0

    fi

    fail "$component" "File not found: $file"

    return 1
}

############################################################
# Command
############################################################

check_command() {

    local command="$1"

    reset_result

    if command -v "$command" >/dev/null 2>&1; then

        pass "$command" "Installed"

        return 0

    fi

    fail "$command" "Not installed"

    return 1
}

############################################################
# Service
############################################################

check_service() {

    local component="$1"
    local function_name="$2"

    reset_result

    if "$function_name"; then

        pass "$component" "Running"

        return 0

    fi

    fail "$component" "Service not running" "$SEVERITY_CRITICAL"

    return 1
}

############################################################
# API
############################################################

check_api() {

    local component="$1"
    local url="$2"

    reset_result

    if curl \
        --silent \
        --fail \
        --max-time 5 \
        "$url" >/dev/null 2>&1; then

        pass "$component" "Reachable"

        return 0

    fi

    fail "$component" "API unreachable" "$SEVERITY_CRITICAL"

    return 1
}

############################################################
# TCP Port
############################################################

check_port() {

    local component="$1"
    local host="$2"
    local port="$3"

    reset_result

    if nc -z "$host" "$port" >/dev/null 2>&1; then

        pass "$component" "Port $port open"

        return 0

    fi

    fail "$component" "Port $port closed"

    return 1
}

############################################################
# Disk Space
############################################################

check_disk_space() {

    local path="$1"
    local minimum_gb="$2"

    local available

    reset_result

    available=$(df -Pk "$path" | awk 'NR==2 {print $4}')
    available=$((available / 1024 / 1024))

    if (( available >= minimum_gb )); then

        pass "Disk Space" "${available} GB available"

        return 0

    fi

    warn "Disk Space" "Only ${available} GB available" "$SEVERITY_MEDIUM"

    return 1
}

############################################################
# Memory
############################################################

check_memory() {

    local minimum_gb="$1"

    local installed

    reset_result

    installed=$(sysctl -n hw.memsize)
    installed=$((installed / 1024 / 1024 / 1024))

    if (( installed >= minimum_gb )); then

        pass "Memory" "${installed} GB installed"

        return 0

    fi

    fail "Memory" "${installed} GB installed" "$SEVERITY_HIGH"

    return 1
}

############################################################
# Git Repository
############################################################

check_git_repository() {

    reset_result

    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then

        pass "Git Repository" "Repository detected"

        return 0

    fi

    fail "Git Repository" "Repository not detected"

    return 1
}

############################################################
# Model
############################################################

check_model() {

    local model="$1"

    reset_result

    if ollama list 2>/dev/null | awk '{print $1}' | grep -Fxq "$model"; then

        pass "$model" "Installed"

        return 0

    fi

    warn "$model" "Model not installed"

    return 1
}