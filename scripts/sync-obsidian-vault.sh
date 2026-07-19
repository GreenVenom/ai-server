#!/bin/bash
set -euo pipefail
SERVER_ROOT="${HOME}/server"
REPO_ROOT="${SERVER_ROOT}/data/obsidian/repos/personal-knowledge-source"
REPO_VAULT_ROOT="${REPO_ROOT}"
MIRROR_ROOT="${SERVER_ROOT}/data/obsidian/vaults/personal-knowledge"
STATE_ROOT="${SERVER_ROOT}/data/obsidian/state"
LOG_ROOT="${SERVER_ROOT}/logs/obsidian"
LOCK_DIR="${STATE_ROOT}/personal-knowledge-sync.lock"
COMMIT_FILE="${STATE_ROOT}/personal-knowledge-source.commit"
cleanup() { rmdir "${LOCK_DIR}" 2>/dev/null || true; }
mkdir -p "${STATE_ROOT}" "${LOG_ROOT}" "${MIRROR_ROOT}"
if ! mkdir "${LOCK_DIR}" 2>/dev/null; then
    printf 'ERROR: Obsidian synchronization is already running\n' >&2
    exit 1
fi
trap cleanup EXIT INT TERM
[[ -d "${REPO_ROOT}/.git" ]] || { printf 'ERROR: Repository clone is missing: %s\n' "${REPO_ROOT}" >&2; exit 1; }
[[ -d "${REPO_VAULT_ROOT}/.obsidian" ]] || { printf 'ERROR: Selected source is not an Obsidian vault: %s\n' "${REPO_VAULT_ROOT}" >&2; exit 1; }
git -C "${REPO_ROOT}" fetch --prune origin
git -C "${REPO_ROOT}" merge --ff-only '@{u}'
source_commit="$(git -C "${REPO_ROOT}" rev-parse HEAD)"
rsync --archive --delete-delay --prune-empty-dirs --include='*/' --include='*.md' --exclude='*' "${REPO_VAULT_ROOT}/" "${MIRROR_ROOT}/"
find "${MIRROR_ROOT}" -type d -exec chmod 700 {} +
find "${MIRROR_ROOT}" -type f -name '*.md' -exec chmod 600 {} +
printf '%s\n' "${source_commit}" > "${COMMIT_FILE}"
chmod 600 "${COMMIT_FILE}"
note_count="$(find "${MIRROR_ROOT}" -type f -name '*.md' | wc -l | tr -d ' ')"
printf 'repository_commit=%s\n' "${source_commit}"
printf 'markdown_note_count=%s\n' "${note_count}"
printf 'mirror_root=%s\n' "${MIRROR_ROOT}"
