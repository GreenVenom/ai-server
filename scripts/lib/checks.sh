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
# Version: 3.0.0
#
############################################################

execute_check() {
    local check_rc=0

    reset_result

    "$@" || check_rc=$?

    CHECK_COUNT=$((CHECK_COUNT + 1))

    case "$RESULT_STATUS" in
        PASS)
            PASS_COUNT=$((PASS_COUNT + 1))
            print_success "$RESULT_COMPONENT"
            ;;
        WARN)
            WARN_COUNT=$((WARN_COUNT + 1))
            print_warning "$RESULT_COMPONENT"
            ;;
        FAIL)
            FAIL_COUNT=$((FAIL_COUNT + 1))
            print_error "$RESULT_COMPONENT"
            ;;
        *)
            FAIL_COUNT=$((FAIL_COUNT + 1))
            RESULT_STATUS="FAIL"
            RESULT_COMPONENT="Framework"
            RESULT_MESSAGE="Unknown check result from: $*"
            RESULT_SEVERITY="$SEVERITY_CRITICAL"
            print_error "Framework"
            check_rc=1
            ;;
    esac

    printf "    %s\n" "$RESULT_MESSAGE"
    log_info "$RESULT_STATUS [$RESULT_SEVERITY] $RESULT_COMPONENT - $RESULT_MESSAGE"

    return 0
}

check_directory() {
    local component="$1"
    local directory="$2"

    reset_result

    if [[ -d "$directory" ]]; then
        pass "$component" "Directory exists: $directory"
        return 0
    fi

    fail "$component" "Directory not found: $directory"
    return 1
}

check_writable_directory() {
    local component="$1"
    local directory="$2"

    reset_result

    if [[ -d "$directory" && -r "$directory" && -w "$directory" ]]; then
        pass "$component" "Directory is readable and writable: $directory"
        return 0
    fi

    fail "$component" "Directory is not readable and writable: $directory" "$SEVERITY_HIGH"
    return 1
}

check_file() {
    local component="$1"
    local file="$2"

    reset_result

    if [[ -f "$file" ]]; then
        pass "$component" "File exists: $file"
        return 0
    fi

    fail "$component" "File not found: $file"
    return 1
}

check_command() {
    local command="$1"

    reset_result

    if command -v "$command" >/dev/null 2>&1; then
        pass "$command" "Installed: $(command -v "$command")"
        return 0
    fi

    fail "$command" "Not installed"
    return 1
}

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

check_condition() {
    local component="$1"
    local success_message="$2"
    local failure_message="$3"
    local severity="$4"
    local function_name="$5"

    reset_result

    if "$function_name"; then
        pass "$component" "$success_message"
        return 0
    fi

    fail "$component" "$failure_message" "$severity"
    return 1
}

check_optional_condition() {
    local component="$1"
    local success_message="$2"
    local warning_message="$3"
    local function_name="$4"

    reset_result

    if "$function_name"; then
        pass "$component" "$success_message"
        return 0
    fi

    warn "$component" "$warning_message" "$SEVERITY_LOW"
    return 1
}

check_api() {
    local component="$1"
    local url="$2"

    reset_result

    if curl --silent --fail --max-time 5 "$url" >/dev/null 2>&1; then
        pass "$component" "Reachable: $url"
        return 0
    fi

    fail "$component" "API unreachable: $url" "$SEVERITY_CRITICAL"
    return 1
}

check_port() {
    local component="$1"
    local host="$2"
    local port="$3"

    reset_result

    if nc -z "$host" "$port" >/dev/null 2>&1; then
        pass "$component" "Port $host:$port open"
        return 0
    fi

    fail "$component" "Port $host:$port closed"
    return 1
}

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

check_git_repository() {
    reset_result

    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        pass "Git Repository" "Repository detected"
        return 0
    fi

    fail "Git Repository" "Repository not detected"
    return 1
}

check_model() {
    local model="$1"

    reset_result

    if ollama list 2>/dev/null |
        awk 'NR > 1 {print $1}' |
        grep -Eq "^${model}(:latest)?$"; then
        pass "$model" "Installed"
        return 0
    fi

    warn "$model" "Model not installed"
    return 1
}

check_openclaw_version() {
    reset_result

    if openclaw_installed; then
        pass "OpenClaw Version" "$(openclaw_version)"
        return 0
    fi

    fail "OpenClaw Version" "OpenClaw is not installed" "$SEVERITY_CRITICAL"
    return 1
}

check_openclaw_gateway() {
    check_condition \
        "OpenClaw Gateway" \
        "LaunchAgent loaded and runtime active" \
        "Gateway LaunchAgent is not active" \
        "$SEVERITY_CRITICAL" \
        openclaw_running
}

check_openclaw_rpc() {
    check_condition \
        "OpenClaw RPC" \
        "Gateway connectivity probe passed" \
        "Gateway connectivity probe failed" \
        "$SEVERITY_CRITICAL" \
        openclaw_gateway_reachable
}

check_openclaw_loopback() {
    check_condition \
        "OpenClaw Binding" \
        "Gateway is loopback-only on ${OPENCLAW_GATEWAY_HOST}:${OPENCLAW_GATEWAY_PORT}" \
        "Gateway is not confirmed loopback-only" \
        "$SEVERITY_CRITICAL" \
        openclaw_gateway_loopback_only
}

check_openclaw_config() {
    check_condition \
        "OpenClaw Configuration" \
        "Configuration is valid" \
        "Configuration validation failed" \
        "$SEVERITY_CRITICAL" \
        openclaw_config_valid
}

check_openclaw_models() {
    reset_result

    if openclaw_primary_model_correct && openclaw_fallback_model_correct; then
        pass \
            "OpenClaw Models" \
            "Primary ${OPENCLAW_PRIMARY_MODEL}; fallback ${OPENCLAW_FALLBACK_MODEL}"
        return 0
    fi

    fail \
        "OpenClaw Models" \
        "Expected primary ${OPENCLAW_PRIMARY_MODEL} and fallback ${OPENCLAW_FALLBACK_MODEL}" \
        "$SEVERITY_HIGH"
    return 1
}

check_openclaw_workspace() {
    reset_result

    if openclaw_workspace_configured && openclaw_workspace_available; then
        pass \
            "OpenClaw Workspace" \
            "Configured and writable: ${OPENCLAW_WORKSPACE}"
        return 0
    fi

    fail \
        "OpenClaw Workspace" \
        "Workspace is missing, not writable, or not configured: ${OPENCLAW_WORKSPACE}" \
        "$SEVERITY_HIGH"
    return 1
}

check_openclaw_docker_socket() {
    reset_result

    if openclaw_docker_socket_configured && docker_socket_available; then
        pass \
            "OpenClaw Docker Socket" \
            "Configured and available: ${OPENCLAW_DOCKER_SOCKET}"
        return 0
    fi

    fail \
        "OpenClaw Docker Socket" \
        "Docker socket is unavailable or missing from ${OPENCLAW_ENV_FILE}" \
        "$SEVERITY_CRITICAL"
    return 1
}

check_openclaw_sandbox_image() {
    check_condition \
        "OpenClaw Sandbox Image" \
        "Available: ${OPENCLAW_SANDBOX_IMAGE}" \
        "Sandbox image not available: ${OPENCLAW_SANDBOX_IMAGE}" \
        "$SEVERITY_CRITICAL" \
        docker_sandbox_image_available
}

check_openclaw_sandbox_policy() {
    reset_result

    if openclaw_sandbox_mode_all &&
        openclaw_sandbox_workspace_rw &&
        openclaw_elevated_disabled &&
        openclaw_web_tools_disabled; then

        pass \
            "OpenClaw Sandbox Policy" \
            "Sandbox=all, workspace=rw, elevated=off, web/browser=off"
        return 0
    fi

    fail \
        "OpenClaw Sandbox Policy" \
        "Effective sandbox policy does not match the M03 security baseline" \
        "$SEVERITY_CRITICAL"
    return 1
}

check_openclaw_memory_search() {
    check_condition \
        "OpenClaw Memory Search" \
        "Cloud memory search disabled" \
        "Cloud memory search is not confirmed disabled" \
        "$SEVERITY_HIGH" \
        openclaw_memory_search_disabled
}

check_openclaw_security() {
    reset_result

    local critical_count
    critical_count="$(openclaw_security_critical_count 2>/dev/null)" || critical_count="unknown"

    if [[ "$critical_count" == "0" ]]; then
        pass "OpenClaw Security" "Deep audit reports 0 critical findings"
        return 0
    fi

    fail \
        "OpenClaw Security" \
        "Deep audit critical findings: ${critical_count}" \
        "$SEVERITY_CRITICAL"
    return 1
}

check_openclaw_sandbox_runtime() {
    check_optional_condition \
        "OpenClaw Sandbox Runtime" \
        "At least one sandbox runtime is running" \
        "No sandbox runtime is currently running; it may be created on demand" \
        openclaw_sandbox_runtime_running
}
