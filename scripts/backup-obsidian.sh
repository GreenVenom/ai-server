#!/bin/bash
set -euo pipefail
SERVER_ROOT="${HOME}/server"
BACKUP_ROOT="${SERVER_ROOT}/backups/obsidian"
QDRANT_URL="http://127.0.0.1:6333"
COLLECTION="obsidian_chunks_v1"
timestamp="$(date -u '+%Y%m%dT%H%M%SZ')"
backup_dir="${BACKUP_ROOT}/${timestamp}"
archive_path="${BACKUP_ROOT}/obsidian-${timestamp}.tar.gz"
cleanup() { rm -rf "${backup_dir}"; }
trap cleanup EXIT INT TERM
mkdir -p "${backup_dir}/config" "${backup_dir}/state" "${backup_dir}/services/obsidian" "${backup_dir}/services/openclaw-obsidian-plugin" "${backup_dir}/scripts" "${backup_dir}/launchagent" "${backup_dir}/qdrant"
copy_if_present() { source_path="$1"; destination="$2"; [[ -e "${source_path}" ]] && cp -R "${source_path}" "${destination}" || true; }
copy_if_present "${SERVER_ROOT}/config/obsidian" "${backup_dir}/config/"
copy_if_present "${SERVER_ROOT}/data/obsidian/manifests" "${backup_dir}/state/"
copy_if_present "${SERVER_ROOT}/data/obsidian/state/personal-knowledge-source.commit" "${backup_dir}/state/"
copy_if_present "${SERVER_ROOT}/data/obsidian/state/personal-knowledge-job-state.json" "${backup_dir}/state/"
copy_if_present "${SERVER_ROOT}/services/obsidian/src" "${backup_dir}/services/obsidian/"
copy_if_present "${SERVER_ROOT}/services/openclaw-obsidian-plugin/src" "${backup_dir}/services/openclaw-obsidian-plugin/"
for file in package.json package-lock.json tsconfig.json openclaw.plugin.json; do copy_if_present "${SERVER_ROOT}/services/openclaw-obsidian-plugin/${file}" "${backup_dir}/services/openclaw-obsidian-plugin/"; done
for script in sync-obsidian-vault.sh obsidian-sync-index.sh obsidian-sync-index-runner.sh obsidian-search.sh check-obsidian.sh cleanup-obsidian-logs.sh backup-obsidian.sh; do copy_if_present "${SERVER_ROOT}/scripts/${script}" "${backup_dir}/scripts/"; done
copy_if_present "${HOME}/Library/LaunchAgents/ai.openclaw.obsidian-sync-index.plist" "${backup_dir}/launchagent/"
snapshot_response="$(curl --fail --silent --show-error -X POST "${QDRANT_URL}/collections/${COLLECTION}/snapshots")"
snapshot_name="$(python3 - "${snapshot_response}" <<'PY'
import json,sys
print(json.loads(sys.argv[1])["result"]["name"])
PY
)"
curl --fail --silent --show-error "${QDRANT_URL}/collections/${COLLECTION}/snapshots/${snapshot_name}" --output "${backup_dir}/qdrant/${snapshot_name}"
snapshot_checksum="$(shasum -a 256 "${backup_dir}/qdrant/${snapshot_name}" | awk '{print $1}')"
cat > "${backup_dir}/backup-metadata.json" <<JSON
{"schema_version":2,"backup_type":"obsidian-operational-state","created_at":"$(date -u '+%Y-%m-%dT%H:%M:%SZ')","collection":"${COLLECTION}","qdrant_snapshot":"${snapshot_name}","qdrant_snapshot_sha256":"${snapshot_checksum}","authoritative_vault_location":"private GitHub repository","server_mirror_included":false,"python_virtual_environment_included":false,"node_modules_included":false}
JSON
find "${backup_dir}" -type d -exec chmod 700 {} +
find "${backup_dir}" -type f -exec chmod 600 {} +
tar -C "${BACKUP_ROOT}" -czf "${archive_path}" "${timestamp}"
chmod 600 "${archive_path}"
printf 'status=success\narchive=%s\nqdrant_snapshot=%s\nsnapshot_sha256=%s\n' "${archive_path}" "${snapshot_name}" "${snapshot_checksum}"
