#!/bin/bash
set -euo pipefail
SERVER_ROOT="${HOME}/server"
PYTHON_BIN="${SERVER_ROOT}/services/obsidian/venv/bin/python"
SOURCE_ROOT="${SERVER_ROOT}/services/obsidian/src"
exec env PYTHONPATH="${SOURCE_ROOT}" "${PYTHON_BIN}" -m obsidian_ingest.retrieval_boundary "$@"
