#!/bin/bash
set -uo pipefail
SERVER_ROOT="${HOME}/server"
JOB_SCRIPT="${SERVER_ROOT}/scripts/obsidian-sync-index.sh"
STATE_ROOT="${SERVER_ROOT}/data/obsidian/state"
STATE_FILE="${STATE_ROOT}/personal-knowledge-job-state.json"
mkdir -p "${STATE_ROOT}"
started_at="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
if "${JOB_SCRIPT}"; then exit_code=0; job_status="success"; else exit_code=$?; job_status="failed"; fi
completed_at="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
temporary_file="$(mktemp "${STATE_ROOT}/.personal-knowledge-job-state.XXXXXX")"
STATUS="${job_status}" EXIT_CODE="${exit_code}" STARTED_AT="${started_at}" COMPLETED_AT="${completed_at}" LATEST_LOG="${SERVER_ROOT}/logs/obsidian/personal-knowledge-latest.log" python3 - "${temporary_file}" <<'PY'
import json, os, sys
from pathlib import Path
path = Path(sys.argv[1])
payload = {"schema_version": 1, "job": "obsidian-sync-index", "vault_id": "personal-knowledge", "status": os.environ["STATUS"], "exit_code": int(os.environ["EXIT_CODE"]), "started_at": os.environ["STARTED_AT"], "completed_at": os.environ["COMPLETED_AT"], "latest_log": os.environ["LATEST_LOG"]}
path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
path.chmod(0o600)
PY
mv "${temporary_file}" "${STATE_FILE}"
exit "${exit_code}"
