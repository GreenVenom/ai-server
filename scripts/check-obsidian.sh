#!/bin/bash
set -u
SERVER_ROOT="${HOME}/server"
STATE_FILE="${SERVER_ROOT}/data/obsidian/state/personal-knowledge-job-state.json"
MANIFEST_FILE="${SERVER_ROOT}/data/obsidian/manifests/personal-knowledge.json"
MIRROR_ROOT="${SERVER_ROOT}/data/obsidian/vaults/personal-knowledge"
COMMIT_FILE="${SERVER_ROOT}/data/obsidian/state/personal-knowledge-source.commit"
PYTHON_BIN="${SERVER_ROOT}/services/obsidian/venv/bin/python"
SOURCE_ROOT="${SERVER_ROOT}/services/obsidian/src"
COLLECTION="obsidian_chunks_v1"
VAULT_ID="personal-knowledge"
failed=0
pass() { printf 'PASS: %s\n' "$1"; }
fail() { printf 'FAIL: %s\n' "$1" >&2; failed=$((failed + 1)); }
[[ -f "${STATE_FILE}" ]] && pass "Job state exists" || fail "Job state is missing"
[[ -f "${MANIFEST_FILE}" ]] && pass "Manifest exists" || fail "Manifest is missing"
[[ -d "${MIRROR_ROOT}" ]] && pass "Mirror exists" || fail "Mirror is missing"
[[ -f "${COMMIT_FILE}" ]] && pass "Source commit state exists" || fail "Source commit state is missing"
if launchctl print "gui/$(id -u)/ai.openclaw.obsidian-sync-index" >/dev/null 2>&1; then pass "LaunchAgent is loaded"; else fail "LaunchAgent is not loaded"; fi
if [[ -f "${STATE_FILE}" ]]; then
  job_status="$(python3 - "${STATE_FILE}" <<'PY'
import json, sys
from pathlib import Path
print(json.loads(Path(sys.argv[1]).read_text(encoding="utf-8")).get("status", "unknown"))
PY
)"
  [[ "${job_status}" == "success" ]] && pass "Last job completed successfully" || fail "Last job status is ${job_status}"
fi
if [[ -x "${PYTHON_BIN}" && -f "${MANIFEST_FILE}" ]]; then
if PYTHONPATH="${SOURCE_ROOT}" "${PYTHON_BIN}" - "${MANIFEST_FILE}" "${COLLECTION}" "${VAULT_ID}" "${MIRROR_ROOT}" <<'PY'
import json, sys, urllib.request
from pathlib import Path
from obsidian_ingest.manifest import load_manifest
manifest_path, collection, vault_id, mirror_root = Path(sys.argv[1]), sys.argv[2], sys.argv[3], Path(sys.argv[4])
manifest = load_manifest(manifest_path, required=True)
manifest_ids = {cid for doc in manifest.documents.values() for cid in doc.chunk_ids}
markdown_count = len(list(mirror_root.rglob("*.md")))
request = urllib.request.Request(f"http://127.0.0.1:6333/collections/{collection}/points/scroll", data=json.dumps({"limit":10000,"with_payload":False,"with_vector":False,"filter":{"must":[{"key":"vault_id","match":{"value":vault_id}}]}}).encode(), method="POST", headers={"Content-Type":"application/json"})
with urllib.request.urlopen(request, timeout=30) as response: points=json.load(response)["result"]["points"]
qdrant_ids={p["id"] for p in points}
print(f"mirror_document_count={markdown_count}")
print(f"manifest_document_count={len(manifest.documents)}")
print(f"manifest_chunk_count={len(manifest_ids)}")
print(f"qdrant_chunk_count={len(qdrant_ids)}")
assert manifest.vault_id == vault_id
assert len(manifest.documents) == markdown_count
assert manifest_ids == qdrant_ids
PY
then pass "Manifest, mirror, and Qdrant reconcile"; else fail "Manifest, mirror, and Qdrant do not reconcile"; fi
fi
printf '\nFailed: %d\n' "${failed}"
[[ "${failed}" -eq 0 ]]
