#!/bin/bash
set -euo pipefail
LOG_ROOT="${HOME}/server/logs/obsidian"
RETENTION_DAYS=30
find "${LOG_ROOT}" -type f -name 'personal-knowledge-*.log' -mtime "+${RETENTION_DAYS}" -print -delete
printf 'status=success\nretention_days=%s\n' "${RETENTION_DAYS}"
