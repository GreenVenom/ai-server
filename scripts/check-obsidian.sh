#!/bin/bash

set -u

SERVER_ROOT="${HOME}/server"

STATE_FILE="${SERVER_ROOT}/data/obsidian/state/personal-knowledge-job-state.json"
MANIFEST_FILE="${SERVER_ROOT}/data/obsidian/manifests-v2/personal-knowledge.json"
MIRROR_ROOT="${SERVER_ROOT}/data/obsidian/vaults/personal-knowledge"
COMMIT_FILE="${SERVER_ROOT}/data/obsidian/state/personal-knowledge-source.commit"

PYTHON_BIN="${SERVER_ROOT}/services/obsidian/venv/bin/python"
SOURCE_ROOT="${SERVER_ROOT}/services/obsidian/src"

COLLECTION="obsidian_chunks_v2"
VAULT_ID="personal-knowledge"

failed=0

pass() {
    printf 'PASS: %s\n' "$1"
}

fail() {
    printf 'FAIL: %s\n' "$1" >&2
    failed=$((failed + 1))
}

if [[ -f "${STATE_FILE}" ]]; then
    pass "Job state exists"
else
    fail "Job state is missing"
fi

if [[ -f "${MANIFEST_FILE}" ]]; then
    pass "Manifest exists"
else
    fail "Manifest is missing"
fi

if [[ -d "${MIRROR_ROOT}" ]]; then
    pass "Mirror exists"
else
    fail "Mirror is missing"
fi

if [[ -f "${COMMIT_FILE}" ]]; then
    pass "Source commit state exists"
else
    fail "Source commit state is missing"
fi

if launchctl print \
    "gui/$(id -u)/ai.openclaw.obsidian-sync-index" \
    >/dev/null 2>&1
then
    pass "LaunchAgent is loaded"
else
    fail "LaunchAgent is not loaded"
fi

if [[ -f "${STATE_FILE}" ]]; then
    job_status="$(
        python3 - "${STATE_FILE}" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
data = json.loads(path.read_text(encoding="utf-8"))
print(data.get("status", "unknown"))
PY
    )"

    if [[ "${job_status}" == "success" ]]; then
        pass "Last job completed successfully"
    else
        fail "Last job status is ${job_status}"
    fi
fi

if [[ -x "${PYTHON_BIN}" && -f "${MANIFEST_FILE}" ]]; then
    if PYTHONPATH="${SOURCE_ROOT}" \
        "${PYTHON_BIN}" - \
        "${MANIFEST_FILE}" \
        "${COLLECTION}" \
        "${VAULT_ID}" \
        "${MIRROR_ROOT}"
    then
        pass "Manifest, mirror, and Qdrant reconcile"
    else
        fail "Manifest, mirror, and Qdrant do not reconcile"
    fi <<'PY'
import json
import sys
import urllib.request
from pathlib import Path

from obsidian_ingest.manifest import load_manifest

manifest_path = Path(sys.argv[1])
collection = sys.argv[2]
vault_id = sys.argv[3]
mirror_root = Path(sys.argv[4])

manifest = load_manifest(
    manifest_path,
    required=True,
)

manifest_ids = {
    chunk_id
    for document in manifest.documents.values()
    for chunk_id in document.chunk_ids
}

markdown_count = len(
    list(mirror_root.rglob("*.md"))
)

url = (
    "http://127.0.0.1:6333/"
    f"collections/{collection}/points/scroll"
)

payload = json.dumps(
    {
        "limit": 10000,
        "with_payload": False,
        "with_vector": False,
        "filter": {
            "must": [
                {
                    "key": "vault_id",
                    "match": {"value": vault_id},
                }
            ]
        },
    }
).encode("utf-8")

request = urllib.request.Request(
    url,
    data=payload,
    method="POST",
    headers={"Content-Type": "application/json"},
)

with urllib.request.urlopen(request, timeout=30) as response:
    points = json.load(response)["result"]["points"]

qdrant_ids = {
    point["id"]
    for point in points
}

print(f"mirror_document_count={markdown_count}")
print(f"manifest_document_count={len(manifest.documents)}")
print(f"manifest_chunk_count={len(manifest_ids)}")
print(f"qdrant_chunk_count={len(qdrant_ids)}")

assert manifest.vault_id == vault_id
print(
    "unindexed_or_excluded_markdown_count="
    f"{markdown_count - len(manifest.documents)}"
)
assert manifest_ids == qdrant_ids
PY
fi

printf '\nFailed: %d\n' "${failed}"

if [[ "${failed}" -ne 0 ]]; then
    exit 1
fi
