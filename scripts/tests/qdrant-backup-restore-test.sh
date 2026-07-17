#!/usr/bin/env bash
set -euo pipefail

readonly OLLAMA_URL="${OLLAMA_URL:-http://127.0.0.1:11434}"
readonly QDRANT_URL="${QDRANT_URL:-http://127.0.0.1:6333}"
readonly SOURCE_COLLECTION="${SOURCE_COLLECTION:-m04_validation}"
readonly RESTORE_COLLECTION="${RESTORE_COLLECTION:-validation_m04_restore_v1}"
readonly VECTOR_NAME="${VECTOR_NAME:-text-dense}"
readonly EXPECTED_VECTOR_SIZE="${EXPECTED_VECTOR_SIZE:-768}"
readonly EXPECTED_DISTANCE="${EXPECTED_DISTANCE:-Cosine}"
readonly EMBEDDING_MODEL="${EMBEDDING_MODEL:-nomic-embed-text:latest}"
readonly RETRIEVAL_POINT_ID="${RETRIEVAL_POINT_ID:-2}"
readonly EXPECTED_RETRIEVAL_TOPIC="${EXPECTED_RETRIEVAL_TOPIC:-openclaw}"
readonly EXPECTED_FIRST_TOPIC="${EXPECTED_FIRST_TOPIC:-openclaw}"
readonly EXPECTED_LAST_TOPIC="${EXPECTED_LAST_TOPIC:-control}"
readonly SNAPSHOT_DIR="${SNAPSHOT_DIR:-$HOME/server/backups/qdrant/snapshots}"
readonly MANIFEST_DIR="${MANIFEST_DIR:-$HOME/server/backups/qdrant/manifests}"
readonly KEEP_RESTORE_COLLECTION="${KEEP_RESTORE_COLLECTION:-false}"
readonly DELETE_INTERNAL_SNAPSHOT="${DELETE_INTERNAL_SNAPSHOT:-true}"

PASSED=0
FAILED=0
RESTORE_CREATED=false
SNAPSHOT_NAME=""

header() {
  printf '\n============================================================\n%s\n============================================================\n' "$1"
}

pass() {
  PASSED=$((PASSED + 1))
  printf 'PASS: %s\n' "$1"
}

fail() {
  FAILED=$((FAILED + 1))
  printf 'FAIL: %s\n' "$1" >&2
}

require_command() {
  if command -v "$1" >/dev/null 2>&1; then
    pass "Required command available: $1"
  else
    fail "Required command missing: $1"
    exit 1
  fi
}

delete_restore_collection() {
  curl --silent --show-error -X DELETE \
    "${QDRANT_URL}/collections/${RESTORE_COLLECTION}" \
    >/dev/null 2>&1 || true
  RESTORE_CREATED=false
}

delete_internal_snapshot() {
  if [[ -n "$SNAPSHOT_NAME" ]]; then
    curl --silent --show-error -X DELETE \
      "${QDRANT_URL}/collections/${SOURCE_COLLECTION}/snapshots/${SNAPSHOT_NAME}" \
      >/dev/null 2>&1 || true
  fi
}

cleanup() {
  exit_code=$?
  if [[ "$RESTORE_CREATED" == "true" && "$KEEP_RESTORE_COLLECTION" != "true" ]]; then
    delete_restore_collection
  fi
  if [[ "$DELETE_INTERNAL_SNAPSHOT" == "true" ]]; then
    delete_internal_snapshot
  fi
  exit "$exit_code"
}

trap cleanup EXIT INT TERM

header "Qdrant M04.6 Backup and Restore Test"

require_command curl
require_command python3
require_command shasum
require_command awk
require_command stat
require_command sed

mkdir -p "$SNAPSHOT_DIR" "$MANIFEST_DIR"

printf '\nConfiguration\n'
printf '  Source collection       : %s\n' "$SOURCE_COLLECTION"
printf '  Restore collection      : %s\n' "$RESTORE_COLLECTION"
printf '  Vector name             : %s\n' "$VECTOR_NAME"
printf '  Expected vector size    : %s\n' "$EXPECTED_VECTOR_SIZE"
printf '  Expected distance       : %s\n' "$EXPECTED_DISTANCE"
printf '  Embedding model         : %s\n' "$EMBEDDING_MODEL"
printf '  Snapshot directory      : %s\n' "$SNAPSHOT_DIR"
printf '  Manifest directory      : %s\n' "$MANIFEST_DIR"
printf '  Keep restore collection : %s\n' "$KEEP_RESTORE_COLLECTION"
printf '  Delete internal snapshot: %s\n' "$DELETE_INTERNAL_SNAPSHOT"

header "Service Readiness"

curl --fail --silent --show-error "${QDRANT_URL}/readyz" >/dev/null
pass "Qdrant is ready"

curl --fail --silent --show-error "${OLLAMA_URL}/api/version" >/dev/null
pass "Ollama API is reachable"

qdrant_version="$(
  curl --fail --silent --show-error "${QDRANT_URL}/" |
  python3 -c '
import json, sys
print(json.load(sys.stdin).get("version", "unknown"))
'
)"
printf 'Qdrant version: %s\n' "$qdrant_version"
pass "Qdrant version detected"

header "Source Collection Validation"

source_metadata="$(
  curl --fail --silent --show-error \
    "${QDRANT_URL}/collections/${SOURCE_COLLECTION}"
)"

source_values="$(
  python3 - \
    "$source_metadata" \
    "$VECTOR_NAME" <<'PY'
import json
import sys

data = json.loads(sys.argv[1])
vector_name = sys.argv[2]
result = data["result"]
vector = result["config"]["params"]["vectors"][vector_name]

print(result["status"])
print(result["points_count"])
print(vector["size"])
print(vector["distance"])
PY
)"

source_status="$(printf '%s\n' "$source_values" | sed -n '1p')"
source_point_count="$(printf '%s\n' "$source_values" | sed -n '2p')"
source_vector_size="$(printf '%s\n' "$source_values" | sed -n '3p')"
source_distance="$(printf '%s\n' "$source_values" | sed -n '4p')"

printf 'status=%s\n' "$source_status"
printf 'points_count=%s\n' "$source_point_count"
printf 'vector_size=%s\n' "$source_vector_size"
printf 'distance=%s\n' "$source_distance"

[[ "$source_status" == "green" ]] || { fail "Source collection is not green"; exit 1; }
pass "Source collection status is green"

[[ "$source_point_count" -gt 0 ]] || { fail "Source collection is empty"; exit 1; }
pass "Source collection is populated"

[[ "$source_vector_size" == "$EXPECTED_VECTOR_SIZE" ]] || { fail "Unexpected vector size"; exit 1; }
pass "Source vector size matches expected contract"

[[ "$source_distance" == "$EXPECTED_DISTANCE" ]] || { fail "Unexpected distance metric"; exit 1; }
pass "Source distance metric matches expected contract"

header "Snapshot Creation"

delete_restore_collection

snapshot_response="$(
  curl --fail --silent --show-error -X POST \
    "${QDRANT_URL}/collections/${SOURCE_COLLECTION}/snapshots?wait=true"
)"

snapshot_values="$(
  printf '%s\n' "$snapshot_response" |
  python3 -c '
import json, sys
result = json.load(sys.stdin)["result"]
print(result["name"])
print(result["size"])
print(result["creation_time"])
print(result["checksum"])
'
)"

SNAPSHOT_NAME="$(printf '%s\n' "$snapshot_values" | sed -n '1p')"
snapshot_size="$(printf '%s\n' "$snapshot_values" | sed -n '2p')"
snapshot_created_at="$(printf '%s\n' "$snapshot_values" | sed -n '3p')"
api_snapshot_checksum="$(printf '%s\n' "$snapshot_values" | sed -n '4p')"

printf 'snapshot_name=%s\n' "$SNAPSHOT_NAME"
printf 'snapshot_size=%s\n' "$snapshot_size"
printf 'snapshot_created_at=%s\n' "$snapshot_created_at"
printf 'api_snapshot_checksum=%s\n' "$api_snapshot_checksum"

[[ -n "$SNAPSHOT_NAME" ]] || { fail "Snapshot name missing"; exit 1; }
pass "Native Qdrant snapshot created"

header "Portable Snapshot Download"

snapshot_path="${SNAPSHOT_DIR}/${SNAPSHOT_NAME}"

curl --fail --silent --show-error --output "$snapshot_path" \
  "${QDRANT_URL}/collections/${SOURCE_COLLECTION}/snapshots/${SNAPSHOT_NAME}"

[[ -f "$snapshot_path" ]] || { fail "Snapshot download failed"; exit 1; }
pass "Snapshot downloaded to host backup directory"

actual_size="$(stat -f '%z' "$snapshot_path")"
printf 'api_size=%s\n' "$snapshot_size"
printf 'downloaded_size=%s\n' "$actual_size"

[[ "$actual_size" == "$snapshot_size" ]] || { fail "Snapshot size mismatch"; exit 1; }
pass "Downloaded snapshot size matches API metadata"

host_snapshot_checksum="$(shasum -a 256 "$snapshot_path" | awk '{print $1}')"
printf 'api_snapshot_checksum=%s\n' "$api_snapshot_checksum"
printf 'host_snapshot_checksum=%s\n' "$host_snapshot_checksum"

[[ "$host_snapshot_checksum" == "$api_snapshot_checksum" ]] || { fail "Snapshot checksum mismatch"; exit 1; }
pass "API and host SHA-256 checksums match"

header "Manifest Creation"

manifest_timestamp="$(
  python3 -c '
from datetime import datetime, timezone
print(datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z"))
'
)"
manifest_path="${MANIFEST_DIR}/${SNAPSHOT_NAME}.json"

python3 - \
  "$manifest_path" \
  "$qdrant_version" \
  "$SNAPSHOT_NAME" \
  "$SOURCE_COLLECTION" \
  "$RESTORE_COLLECTION" \
  "$snapshot_size" \
  "$snapshot_created_at" \
  "$host_snapshot_checksum" \
  "$source_point_count" \
  "$VECTOR_NAME" \
  "$source_vector_size" \
  "$source_distance" \
  "$EMBEDDING_MODEL" \
  "$manifest_timestamp" <<'PY'
import json
import sys

(
    manifest_path,
    qdrant_version,
    snapshot_name,
    source_collection,
    restore_collection,
    snapshot_size,
    snapshot_created_at,
    checksum,
    point_count,
    vector_name,
    vector_size,
    distance,
    embedding_model,
    manifest_created_at,
) = sys.argv[1:]

manifest = {
    "manifest_schema_version": 1,
    "qdrant_version": qdrant_version,
    "snapshot_type": "collection",
    "snapshot_name": snapshot_name,
    "source_collection": source_collection,
    "restore_collection": restore_collection,
    "snapshot_size_bytes": int(snapshot_size),
    "snapshot_created_at": snapshot_created_at,
    "manifest_created_at": manifest_created_at,
    "checksum_algorithm": "sha256",
    "checksum": checksum,
    "collection_schema": {
        "vector_name": vector_name,
        "vector_size": int(vector_size),
        "distance": distance,
    },
    "embedding_contract": {
        "model": embedding_model,
        "dimension": int(vector_size),
    },
    "point_count": int(point_count),
}

with open(manifest_path, "w", encoding="utf-8") as handle:
    json.dump(manifest, handle, indent=2)
    handle.write("\n")
PY

python3 -m json.tool "$manifest_path" >/dev/null
pass "Snapshot manifest created and valid JSON"
printf 'manifest_path=%s\n' "$manifest_path"

header "Snapshot Restore"

restore_response="$(
  curl --fail --silent --show-error -X POST \
    "${QDRANT_URL}/collections/${RESTORE_COLLECTION}/snapshots/upload?wait=true&priority=snapshot&checksum=${host_snapshot_checksum}" \
    --form "snapshot=@${snapshot_path}"
)"

printf '%s\n' "$restore_response" |
python3 -c '
import json, sys
data = json.load(sys.stdin)
raise SystemExit(0 if data.get("result") is True and data.get("status") == "ok" else 1)
'
RESTORE_CREATED=true
pass "Snapshot restored into disposable collection"

header "Restored Collection Validation"

restore_metadata="$(
  curl --fail --silent --show-error \
    "${QDRANT_URL}/collections/${RESTORE_COLLECTION}"
)"

python3 - \
  "$source_metadata" \
  "$restore_metadata" \
  "$VECTOR_NAME" <<'PY'
import json
import sys

source = json.loads(sys.argv[1])["result"]
restored = json.loads(sys.argv[2])["result"]
vector_name = sys.argv[3]

source_vector = source["config"]["params"]["vectors"][vector_name]
restored_vector = restored["config"]["params"]["vectors"][vector_name]

checks = {
    "status_green": restored["status"] == "green",
    "point_count": source["points_count"] == restored["points_count"],
    "vector_size": source_vector["size"] == restored_vector["size"],
    "distance": source_vector["distance"] == restored_vector["distance"],
}

for name, passed in checks.items():
    print("{}={}".format(name, passed))

if not all(checks.values()):
    raise SystemExit("Restored collection metadata differs")
PY

pass "Restored collection status is green"
pass "Restored point count matches source"
pass "Restored vector size matches source"
pass "Restored distance metric matches source"

header "Payload and Vector Recovery"

retrieval_result="$(
  curl --fail --silent --show-error \
    "${QDRANT_URL}/collections/${RESTORE_COLLECTION}/points/${RETRIEVAL_POINT_ID}"
)"

retrieval_values="$(
  python3 - \
    "$retrieval_result" \
    "$VECTOR_NAME" <<'PY'
import json
import sys

data = json.loads(sys.argv[1])
vector_name = sys.argv[2]
result = data["result"]
payload = result["payload"]
vector = result["vector"][vector_name]

print(result["id"])
print(payload.get("title", ""))
print(payload.get("topic", ""))
print(payload.get("embedding_model", ""))
print(payload.get("embedding_dimension", ""))
print(len(vector))
PY
)"

retrieved_topic="$(printf '%s\n' "$retrieval_values" | sed -n '3p')"
retrieved_model="$(printf '%s\n' "$retrieval_values" | sed -n '4p')"
retrieved_payload_dimension="$(printf '%s\n' "$retrieval_values" | sed -n '5p')"
retrieved_vector_dimension="$(printf '%s\n' "$retrieval_values" | sed -n '6p')"

printf '%s\n' "$retrieval_values"

[[ "$retrieved_topic" == "$EXPECTED_RETRIEVAL_TOPIC" ]] || { fail "Unexpected restored topic"; exit 1; }
pass "Expected payload survived restore"

[[ "$retrieved_model" == "$EMBEDDING_MODEL" ]] || { fail "Embedding model metadata changed"; exit 1; }
pass "Embedding model metadata survived restore"

[[ "$retrieved_payload_dimension" == "$EXPECTED_VECTOR_SIZE" ]] || { fail "Payload dimension changed"; exit 1; }
pass "Embedding dimension metadata survived restore"

[[ "$retrieved_vector_dimension" == "$EXPECTED_VECTOR_SIZE" ]] || { fail "Stored vector dimension changed"; exit 1; }
pass "Stored vector survived restore"

header "Semantic Search Recovery"

ranking_output="$(
  python3 - \
    "$OLLAMA_URL" \
    "$QDRANT_URL" \
    "$RESTORE_COLLECTION" \
    "$EMBEDDING_MODEL" \
    "$VECTOR_NAME" \
    "$EXPECTED_FIRST_TOPIC" \
    "$EXPECTED_LAST_TOPIC" <<'PY'
import json
import sys
import urllib.request

(
    ollama_url,
    qdrant_url,
    collection,
    model,
    vector_name,
    expected_first,
    expected_last,
) = sys.argv[1:]

query_text = "Which service manages agents and orchestrates local AI tasks?"

def request_json(url, body):
    request = urllib.request.Request(
        url,
        data=json.dumps(body).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    with urllib.request.urlopen(request) as response:
        return json.load(response)

embedding_result = request_json(
    "{}/api/embed".format(ollama_url),
    {"model": model, "input": query_text},
)
vectors = embedding_result.get("embeddings", [])
if len(vectors) != 1:
    raise SystemExit("Expected one query embedding")

query_result = request_json(
    "{}/collections/{}/points/query".format(qdrant_url, collection),
    {
        "query": vectors[0],
        "using": vector_name,
        "limit": 5,
        "with_payload": True,
        "with_vector": False,
    },
)
points = query_result.get("result", {}).get("points", [])
if not points:
    raise SystemExit("Restored query returned no points")

topics = [point.get("payload", {}).get("topic") for point in points]
if topics[0] != expected_first:
    raise SystemExit("Unexpected first topic: {}".format(topics))
if topics[-1] != expected_last:
    raise SystemExit("Unexpected last topic: {}".format(topics))

for rank, point in enumerate(points, start=1):
    payload = point.get("payload", {})
    print(
        "{}|{:.6f}|{}|{}".format(
            rank,
            point["score"],
            payload.get("topic"),
            payload.get("title"),
        )
    )
PY
)"

printf '%s\n' "$ranking_output" |
while IFS='|' read -r rank score topic title; do
  printf '%s. score=%s topic=%s title=%s\n' \
    "$rank" "$score" "$topic" "$title"
done

pass "Expected topic ranked first after restore"
pass "Control topic ranked last after restore"

header "Test Summary"

printf 'Passed: %s\n' "$PASSED"
printf 'Failed: %s\n' "$FAILED"
printf 'Snapshot retained: %s\n' "$snapshot_path"
printf 'Manifest retained: %s\n' "$manifest_path"

if [[ "$KEEP_RESTORE_COLLECTION" == "true" ]]; then
  printf 'Restore collection retained: %s\n' "$RESTORE_COLLECTION"
else
  printf 'Restore collection cleanup: scheduled\n'
fi

if [[ "$DELETE_INTERNAL_SNAPSHOT" == "true" ]]; then
  printf 'Internal Qdrant snapshot cleanup: scheduled\n'
else
  printf 'Internal Qdrant snapshot retained: %s\n' "$SNAPSHOT_NAME"
fi

[[ "$FAILED" -eq 0 ]] || exit 1

printf '\nAll Qdrant M04.6 backup and restore tests passed.\n'
