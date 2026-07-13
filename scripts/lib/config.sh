#!/bin/bash

SERVER_ROOT="$HOME/server"

MODEL_DIR="$SERVER_ROOT/data/models/ollama"

LOG_DIR="$HOME/.ollama/logs"

OLLAMA_URL="http://127.0.0.1:11434"

REQUIRED_MODELS=(
    "qwen3:14b"
    "gemma4:12b"
    "nomic-embed-text"
)