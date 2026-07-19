#!/bin/bash
set -uo pipefail
SERVER_ROOT="${HOME}/server"
SYNC_SCRIPT="${SERVER_ROOT}/scripts/sync-obsidian-vault.sh"
PYTHON_BIN="${SERVER_ROOT}/services/obsidian/venv/bin/python"
SOURCE_ROOT="${SERVER_ROOT}/services/obsidian/src"
MIRROR_ROOT="${SERVER_ROOT}/data/obsidian/vaults/personal-knowledge"
MANIFEST_PATH="${SERVER_ROOT}/data/obsidian/manifests/personal-knowledge.json"
STATE_ROOT="${SERVER_ROOT}/data/obsidian/state"
LOG_ROOT="${SERVER_ROOT}/logs/obsidian"
LOCK_DIR="${STATE_ROOT}/personal-knowledge-job.lock"
LATEST_LOG="${LOG_ROOT}/personal-knowledge-latest.log"
VAULT_ID="personal-knowledge"
COLLECTION="obsidian_chunks_v1"
run_started_at="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
run_id="$(date -u '+%Y%m%dT%H%M%SZ')"
log_file="${LOG_ROOT}/personal-knowledge-${run_id}.log"
cleanup() { rmdir "${LOCK_DIR}" 2>/dev/null || true; }
fail() { message="$1"; printf 'status=failed\n'; printf 'error=%s\n' "${message}" >&2; exit 1; }
mkdir -p "${STATE_ROOT}" "${LOG_ROOT}"
if ! mkdir "${LOCK_DIR}" 2>/dev/null; then printf 'ERROR: Production Obsidian job is already running\n' >&2; exit 1; fi
trap cleanup EXIT INT TERM
exec > >(tee -a "${log_file}") 2>&1
ln -sfn "${log_file}" "${LATEST_LOG}"
printf 'job=obsidian-sync-index\nrun_id=%s\nstarted_at=%s\nvault_id=%s\ncollection=%s\n' "${run_id}" "${run_started_at}" "${VAULT_ID}" "${COLLECTION}"
[[ -x "${SYNC_SCRIPT}" ]] || fail "Synchronization script is missing or not executable: ${SYNC_SCRIPT}"
[[ -x "${PYTHON_BIN}" ]] || fail "Python environment is missing: ${PYTHON_BIN}"
[[ -d "${MIRROR_ROOT}" ]] || fail "Production mirror is missing: ${MIRROR_ROOT}"
[[ -f "${MANIFEST_PATH}" ]] || fail "Production manifest is missing: ${MANIFEST_PATH}"
printf '\nphase=repository_sync\n'
"${SYNC_SCRIPT}" || fail "Repository synchronization failed"
printf '\nphase=incremental_index\n'
PYTHONPATH="${SOURCE_ROOT}" "${PYTHON_BIN}" -m obsidian_ingest.incremental "${MIRROR_ROOT}" --vault-id "${VAULT_ID}" --collection "${COLLECTION}" || fail "Incremental indexing failed"
completed_at="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
printf '\nstatus=success\ncompleted_at=%s\nlog_file=%s\n' "${completed_at}" "${log_file}"
