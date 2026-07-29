#!/bin/bash
#
# Create, verify, and retain encrypted off-host recovery sets for the personal
# AI server.  Secrets are intentionally read only from a protected local file.

set -uo pipefail

# launchd supplies only a system PATH. Homebrew installs rclone under
# /opt/homebrew/bin on Apple Silicon (or /usr/local/bin on older Macs).
PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
export PATH

SERVER_HOME="${HOME}/server"
QDRANT_URL="${QDRANT_URL:-http://127.0.0.1:6333}"
COLLECTION="${BACKUP_COLLECTION:-obsidian_chunks_v2}"
RCLONE_REMOTE="${RCLONE_REMOTE:-gdrive_backup_crypt:}"
RCLONE_QUOTA_REMOTE="${RCLONE_QUOTA_REMOTE:-gdrive_backup:}"
RCLONE_SECRET_FILE="${RCLONE_SECRET_FILE:-${SERVER_HOME}/config/backup/rclone.env}"
BACKUP_ROOT="${BACKUP_ROOT:-${SERVER_HOME}/backups/offhost}"
STATE_FILE="${BACKUP_STATE_FILE:-${SERVER_HOME}/data/backup/offhost-backup-state.json}"
LOG_FILE="${BACKUP_LOG_FILE:-${SERVER_HOME}/logs/backup/offhost-backup.log}"

# Retention is defined by ADR-0023.  The capacity reserve deliberately leaves
# 1 GiB plus twice the new set's size available in the free Google Drive tier.
MINIMUM_REMOTE_FREE_BYTES=$((1024 * 1024 * 1024))
DAILY_RETENTION=7
WEEKLY_RETENTION=4
MONTHLY_RETENTION=6

run_started="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
run_id="$(date -u +%Y-%m-%dT%H%M%SZ)"
run_dir="${BACKUP_ROOT}/sets/${run_id}"
outcome="failed"
message="Backup did not complete"
stage_dir=""

mkdir -p "$(dirname "$STATE_FILE")" "$(dirname "$LOG_FILE")" "$run_dir" || exit 1
chmod 700 "$(dirname "$STATE_FILE")" "$BACKUP_ROOT" "${BACKUP_ROOT}/sets" 2>/dev/null || true
chmod 700 "$(dirname "$LOG_FILE")" 2>/dev/null || true

log() {
    printf '%s %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*" | tee -a "$LOG_FILE"
}

write_state() {
    local exit_code="$1"
    local temporary_state="${STATE_FILE}.partial"

    BACKUP_STARTED="$run_started" \
    BACKUP_FINISHED="$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    BACKUP_RUN_ID="$run_id" \
    BACKUP_OUTCOME="$outcome" \
    BACKUP_MESSAGE="$message" \
    BACKUP_EXIT_CODE="$exit_code" \
    python3 - "$temporary_state" <<'PY'
import json
import os
import sys
from pathlib import Path

Path(sys.argv[1]).write_text(json.dumps({
    "schema_version": 1,
    "started_at": os.environ["BACKUP_STARTED"],
    "finished_at": os.environ["BACKUP_FINISHED"],
    "run_id": os.environ["BACKUP_RUN_ID"],
    "status": os.environ["BACKUP_OUTCOME"],
    "message": os.environ["BACKUP_MESSAGE"],
    "exit_code": int(os.environ["BACKUP_EXIT_CODE"]),
}, indent=2) + "\n")
PY
    mv "$temporary_state" "$STATE_FILE" 2>/dev/null || true
    chmod 600 "$STATE_FILE" 2>/dev/null || true
}

cleanup() {
    local exit_code=$?
    [[ -n "$stage_dir" && -d "$stage_dir" ]] && rm -rf "$stage_dir"
    write_state "$exit_code"
    log "result=${outcome} run_id=${run_id} message=${message}"
}
trap cleanup EXIT

fail() {
    message="$1"
    log "ERROR: $message"
    exit 1
}

require_file() {
    [[ -f "$1" ]] || fail "Required allow-listed input is missing: $1"
}

copy_allowlisted_file() {
    local source="$1"
    local relative_destination="$2"
    require_file "$source"
    mkdir -p "${stage_dir}/$(dirname "$relative_destination")" || fail "Could not stage $relative_destination"
    cp -p "$source" "${stage_dir}/${relative_destination}" || fail "Could not stage $relative_destination"
}

if [[ ! -f "$RCLONE_SECRET_FILE" ]]; then
    fail "Protected rclone secret file is missing"
fi

if [[ "$(stat -f '%Lp' "$RCLONE_SECRET_FILE" 2>/dev/null || true)" != "600" ]]; then
    fail "Protected rclone secret file must have mode 600"
fi

RCLONE_CONFIG_PASS="$(awk -F= '$1 == "RCLONE_CONFIG_PASS" {sub(/^[^=]*=/, ""); print; exit}' "$RCLONE_SECRET_FILE")"
[[ -n "$RCLONE_CONFIG_PASS" ]] || fail "RCLONE_CONFIG_PASS is missing from the protected secret file"
export RCLONE_CONFIG_PASS

command -v rclone >/dev/null 2>&1 || fail "rclone is not installed"
command -v curl >/dev/null 2>&1 || fail "curl is not installed"
command -v shasum >/dev/null 2>&1 || fail "shasum is not installed"

log "Starting encrypted off-host backup for collection=${COLLECTION}"

collection_json="$(curl --fail --silent --show-error "${QDRANT_URL}/collections/${COLLECTION}")" \
    || fail "Could not read the active Qdrant collection"

if ! printf '%s' "$collection_json" | python3 -c '
import json, sys
data = json.load(sys.stdin)["result"]
vector = data["config"]["params"]["vectors"]["text-dense"]
assert data["status"] == "green"
assert vector["size"] == 768
assert vector["distance"] == "Cosine"
'; then
    fail "Qdrant collection contract is not green/text-dense/768/Cosine"
fi

snapshot_json="$(curl --fail --silent --show-error -X POST \
    "${QDRANT_URL}/collections/${COLLECTION}/snapshots")" \
    || fail "Qdrant snapshot creation failed"
snapshot_name="$(printf '%s' "$snapshot_json" | python3 -c 'import json,sys; print(json.load(sys.stdin)["result"]["name"])')" \
    || fail "Could not read the Qdrant snapshot name"
[[ -n "$snapshot_name" ]] || fail "Qdrant returned an empty snapshot name"

snapshot_path="${run_dir}/${snapshot_name}"
if ! curl --fail --silent --show-error \
    "${QDRANT_URL}/collections/${COLLECTION}/snapshots/${snapshot_name}" \
    -o "${snapshot_path}.partial"; then
    fail "Could not download the newly created Qdrant snapshot"
fi
mv "${snapshot_path}.partial" "$snapshot_path" || fail "Could not finalize the downloaded snapshot"
snapshot_sha256="$(shasum -a 256 "$snapshot_path" | awk '{print $1}')" || fail "Could not checksum the snapshot"

stage_dir="$(mktemp -d "${TMPDIR:-/tmp}/m08-backup-stage.XXXXXX")" || fail "Could not create staging directory"
copy_allowlisted_file \
    "${SERVER_HOME}/data/obsidian/manifests-v2/personal-knowledge.json" \
    "data/obsidian/manifests-v2/personal-knowledge.json"
copy_allowlisted_file \
    "${SERVER_HOME}/data/obsidian/state/personal-knowledge-source.commit" \
    "data/obsidian/state/personal-knowledge-source.commit"
copy_allowlisted_file \
    "${SERVER_HOME}/docker/qdrant/compose.yaml" \
    "docker/qdrant/compose.yaml"
copy_allowlisted_file "$0" "scripts/backup-offhost.sh"
copy_allowlisted_file \
    "${HOME}/Library/LaunchAgents/com.personal-ai.offhost-backup.plist" \
    "LaunchAgents/com.personal-ai.offhost-backup.plist"

archive_name="runtime-configuration-${run_id}.tar.gz"
archive_path="${run_dir}/${archive_name}"
tar -C "$stage_dir" -czf "$archive_path" . || fail "Could not create the allow-listed runtime archive"
archive_sha256="$(shasum -a 256 "$archive_path" | awk '{print $1}')" || fail "Could not checksum the runtime archive"
source_commit="$(tr -d '\r\n' < "${SERVER_HOME}/data/obsidian/state/personal-knowledge-source.commit")"

BACKUP_RUN_ID="$run_id" BACKUP_CREATED_AT="$run_started" \
SNAPSHOT_NAME="$snapshot_name" SNAPSHOT_SHA256="$snapshot_sha256" \
ARCHIVE_NAME="$archive_name" ARCHIVE_SHA256="$archive_sha256" \
SOURCE_COMMIT="$source_commit" python3 - "${run_dir}/backup-manifest.json" <<'PY'
import json
import os
import sys
from pathlib import Path

manifest = {
    "schema_version": 1,
    "created_at": os.environ["BACKUP_CREATED_AT"],
    "backup_set": os.environ["BACKUP_RUN_ID"],
    "collection": "obsidian_chunks_v2",
    "collection_contract": {
        "vector_name": "text-dense",
        "vector_size": 768,
        "distance": "Cosine",
    },
    "snapshot": {
        "name": os.environ["SNAPSHOT_NAME"],
        "sha256": os.environ["SNAPSHOT_SHA256"],
    },
    "runtime_archive": {
        "name": os.environ["ARCHIVE_NAME"],
        "sha256": os.environ["ARCHIVE_SHA256"],
        "allowlist": [
            "data/obsidian/manifests-v2/personal-knowledge.json",
            "data/obsidian/state/personal-knowledge-source.commit",
            "docker/qdrant/compose.yaml",
            "scripts/backup-offhost.sh",
            "LaunchAgents/com.personal-ai.offhost-backup.plist",
        ],
    },
    "index_metadata": {
        "vault_id": "personal-knowledge",
        "source_commit": os.environ["SOURCE_COMMIT"],
    },
}
Path(sys.argv[1]).write_text(json.dumps(manifest, indent=2) + "\n")
PY

manifest_path="${run_dir}/backup-manifest.json"
manifest_sha256="$(shasum -a 256 "$manifest_path" | awk '{print $1}')" || fail "Could not checksum the backup manifest"
run_bytes="$(du -sk "$run_dir" | awk '{print $1 * 1024}')" || fail "Could not calculate backup-set size"

quota_json="$(rclone about --json "$RCLONE_QUOTA_REMOTE")" || fail "Could not read remote quota"
remote_free_bytes="$(printf '%s' "$quota_json" | python3 -c 'import json,sys; print(json.load(sys.stdin)["free"])')" \
    || fail "Could not parse remote quota"
required_free_bytes=$((MINIMUM_REMOTE_FREE_BYTES + (run_bytes * 2)))
if (( remote_free_bytes < required_free_bytes )); then
    fail "Remote free capacity is below the required safety threshold; no upload or retention cleanup was attempted"
fi

remote_set="${RCLONE_REMOTE}sets/${run_id}"
rclone copy --immutable "$run_dir" "$remote_set" || fail "Encrypted off-host upload failed"
rclone check "$run_dir" "$remote_set" || fail "Encrypted off-host upload verification failed"

retention_listing="$(rclone lsf --dirs-only "${RCLONE_REMOTE}sets")" \
    || fail "Could not list off-host backup sets for retention"
retention_candidates="$(RETENTION_LISTING="$retention_listing" python3 - \
    "$run_id" "$DAILY_RETENTION" "$WEEKLY_RETENTION" "$MONTHLY_RETENTION" <<'PY'
import datetime as dt
import os
import sys

current = sys.argv[1]
daily_limit, weekly_limit, monthly_limit = map(int, sys.argv[2:])
names = sorted({line.strip().rstrip("/") for line in os.environ["RETENTION_LISTING"].splitlines() if line.strip()}, reverse=True)
names = [name for name in names if len(name) == 16 and name.endswith("Z")]

def parse(name):
    return dt.datetime.strptime(name, "%Y-%m-%dT%H%M%SZ")

keep = {current}
for limit, key in (
    (daily_limit, lambda value: value.date().isoformat()),
    (weekly_limit, lambda value: "{}-W{:02d}".format(value.isocalendar().year, value.isocalendar().week)),
    (monthly_limit, lambda value: "{:04d}-{:02d}".format(value.year, value.month)),
):
    seen = set()
    for name in names:
        bucket = key(parse(name))
        if bucket not in seen and len(seen) < limit:
            keep.add(name)
            seen.add(bucket)

for name in names:
    if name not in keep:
        print(name)
PY
)" || fail "Could not calculate off-host retention candidates"

if [[ -n "$retention_candidates" ]]; then
    while IFS= read -r candidate; do
        [[ -n "$candidate" ]] || continue
        rclone purge "${RCLONE_REMOTE}sets/${candidate}" || fail "Retention cleanup failed for an older off-host backup set"
        log "Retention removed off-host backup set=${candidate}"
    done <<< "$retention_candidates"
fi

outcome="success"
message="Verified encrypted off-host backup set ${run_id}; snapshot_sha256=${snapshot_sha256}; archive_sha256=${archive_sha256}; manifest_sha256=${manifest_sha256}"
log "Verified encrypted off-host backup set=${run_id} size_bytes=${run_bytes}"
