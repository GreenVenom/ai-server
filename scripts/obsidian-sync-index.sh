#!/bin/bash

set -uo pipefail

SERVER_ROOT="${HOME}/server"

SYNC_SCRIPT="${SERVER_ROOT}/scripts/sync-obsidian-vault.sh"

PYTHON_BIN="${SERVER_ROOT}/services/obsidian/venv/bin/python"
SOURCE_ROOT="${SERVER_ROOT}/services/obsidian/src"

MIRROR_ROOT="${SERVER_ROOT}/data/obsidian/vaults/personal-knowledge"
MANIFEST_ROOT="${SERVER_ROOT}/data/obsidian/manifests-v2"
MANIFEST_PATH="${MANIFEST_ROOT}/personal-knowledge.json"

STATE_ROOT="${SERVER_ROOT}/data/obsidian/state"
LOG_ROOT="${SERVER_ROOT}/logs/obsidian"

LOCK_DIR="${STATE_ROOT}/personal-knowledge-job.lock"
LATEST_LOG="${LOG_ROOT}/personal-knowledge-latest.log"

VAULT_ID="personal-knowledge"
COLLECTION="obsidian_chunks_v2"

run_started_at="$(
    date -u '+%Y-%m-%dT%H:%M:%SZ'
)"

run_id="$(
    date -u '+%Y%m%dT%H%M%SZ'
)"

log_file="${LOG_ROOT}/personal-knowledge-${run_id}.log"

cleanup() {
    rmdir "${LOCK_DIR}" 2>/dev/null || true
}

fail() {
    message="$1"
    printf 'status=failed\n'
    printf 'error=%s\n' "${message}" >&2
    exit 1
}

mkdir -p \
    "${STATE_ROOT}" \
    "${LOG_ROOT}"

if ! mkdir "${LOCK_DIR}" 2>/dev/null; then
    printf 'ERROR: Production Obsidian job is already running\n' >&2
    exit 1
fi

trap cleanup EXIT INT TERM

exec > >(
    tee -a "${log_file}"
) 2>&1

ln -sfn \
    "${log_file}" \
    "${LATEST_LOG}"

printf 'job=obsidian-sync-index\n'
printf 'run_id=%s\n' "${run_id}"
printf 'started_at=%s\n' "${run_started_at}"
printf 'vault_id=%s\n' "${VAULT_ID}"
printf 'collection=%s\n' "${COLLECTION}"

if [[ ! -x "${SYNC_SCRIPT}" ]]; then
    fail "Synchronization script is missing or not executable: ${SYNC_SCRIPT}"
fi

if [[ ! -x "${PYTHON_BIN}" ]]; then
    fail "Python environment is missing: ${PYTHON_BIN}"
fi

if [[ ! -d "${MIRROR_ROOT}" ]]; then
    fail "Production mirror is missing: ${MIRROR_ROOT}"
fi

if [[ ! -f "${MANIFEST_PATH}" ]]; then
    fail "Production manifest is missing: ${MANIFEST_PATH}"
fi

printf '\nphase=repository_sync\n'

if ! "${SYNC_SCRIPT}"; then
    fail "Repository synchronization failed"
fi

printf '\nphase=incremental_index\n'

if ! PYTHONPATH="${SOURCE_ROOT}" \
    "${PYTHON_BIN}" \
        -m obsidian_ingest.incremental \
        "${MIRROR_ROOT}" \
        --vault-id "${VAULT_ID}" \
        --collection "${COLLECTION}" \
            --manifest-root "${MANIFEST_ROOT}"
then
    fail "Incremental indexing failed"
fi

completed_at="$(
    date -u '+%Y-%m-%dT%H:%M:%SZ'
)"

printf '\nstatus=success\n'
printf 'completed_at=%s\n' "${completed_at}"
printf 'log_file=%s\n' "${log_file}"
