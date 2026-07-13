#!/bin/bash

############################################################
#
# Personal AI Platform
#
# Script: services.sh
#
# Purpose:
# Service discovery and status.
#
# Version: 1.0.0
#
############################################################

############################################################
# Ollama
############################################################

ollama_installed() {
    command -v ollama >/dev/null 2>&1
}

ollama_running() {
    pgrep -x ollama >/dev/null 2>&1
}

ollama_version() {
    ollama --version 2>/dev/null
}

############################################################
# Docker
############################################################

docker_installed() {
    command -v docker >/dev/null 2>&1
}

docker_running() {
    docker info >/dev/null 2>&1
}

docker_version() {
    docker --version 2>/dev/null
}

############################################################
# Tailscale
############################################################

tailscale_installed() {
    command -v tailscale >/dev/null 2>&1
}

tailscale_running() {
    pgrep tailscaled >/dev/null 2>&1
}

############################################################
# Git
############################################################

git_installed() {
    command -v git >/dev/null 2>&1
}

git_version() {
    git --version
}

############################################################
# Future Components
############################################################

openclaw_running() {
    return 1
}

qdrant_running() {
    return 1
}