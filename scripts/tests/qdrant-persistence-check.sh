#!/usr/bin/env bash

set -euo pipefail

readonly OLLAMA_URL="${OLLAMA_URL:-http://127.0.0.1:11434}"
readonly QDRANT_URL="${QDRANT_URL:-http://127.0.0.1:6333}"
readonly COLLECTION="${COLLECTION:-m04_validation}"
readonly VECTOR_NAME="${VECTOR_NAME:-text-dense}"
readonly EXPECTED_POINT_COUNT="${EXPECTED_POINT_COUNT:-5}"
readonly EXPECTED_VECTOR_SIZE="${EXPECTED_VECTOR_SIZE:-768}"
readonly EXPECTED_DISTANCE="${EXPECTED_DISTANCE:-Cosine}"
readonly EMBEDDING_MODEL="${EMBEDDING_MODEL:-nomic-embed-text:latest}"
readonly RETRIEVAL_POINT_ID="${RETRIEVAL_POINT_ID:-2}"

PASSED=0
FAILED=0

header() {
    printf '\n============================================================\n'
    printf '%s\n' "$1"
    printf '============================================================\n'
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

header "Qdrant Persistence Validation"

require_command curl
require_command python3

header "Service Readiness"

curl --fail --silent --show-error \
    "${QDRANT_URL}/readyz" >/dev/null
pass "Qdrant is ready"

curl --fail --silent --show-error \
    "${OLLAMA_URL}/api/version" >/dev/null
pass "Ollama API is reachable"

header "Collection Validation"

metadata="$(
    curl --fail --silent --show-error \
        "${QDRANT_URL}/collections/${COLLECTION}"
)"

collection_values="$(
    python3 - \
        "$metadata" \
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

status="$(printf '%s\n' "$collection_values" | sed -n '1p')"
point_count="$(printf '%s\n' "$collection_values" | sed -n '2p')"
vector_size="$(printf '%s\n' "$collection_values" | sed -n '3p')"
distance="$(printf '%s\n' "$collection_values" | sed -n '4p')"

printf 'status=%s\n' "$status"
printf 'points_count=%s\n' "$point_count"
printf 'vector_name=%s\n' "$VECTOR_NAME"
printf 'vector_size=%s\n' "$vector_size"
printf 'distance=%s\n' "$distance"

[[ "$status" == "green" ]] ||
    { fail "Collection status is not green"; exit 1; }
pass "Collection status is green"

[[ "$point_count" == "$EXPECTED_POINT_COUNT" ]] ||
    { fail "Unexpected point count"; exit 1; }
pass "Point count matches expected value"

[[ "$vector_size" == "$EXPECTED_VECTOR_SIZE" ]] ||
    { fail "Unexpected vector size"; exit 1; }
pass "Vector size matches expected contract"

[[ "$distance" == "$EXPECTED_DISTANCE" ]] ||
    { fail "Unexpected distance metric"; exit 1; }
pass "Distance metric matches expected contract"

header "Direct Retrieval"

point_response="$(
    curl --fail --silent --show-error \
        "${QDRANT_URL}/collections/${COLLECTION}/points/${RETRIEVAL_POINT_ID}"
)"

python3 - \
    "$point_response" \
    "$VECTOR_NAME" \
    "$EXPECTED_VECTOR_SIZE" \
    "$EMBEDDING_MODEL" <<'PY'
import json
import sys

data = json.loads(sys.argv[1])
vector_name = sys.argv[2]
expected_dimension = int(sys.argv[3])
expected_model = sys.argv[4]

result = data["result"]
payload = result["payload"]
vector = result["vector"][vector_name]

checks = {
    "topic": payload.get("topic") == "openclaw",
    "model": payload.get("embedding_model") == expected_model,
    "payload_dimension": (
        payload.get("embedding_dimension") == expected_dimension
    ),
    "vector_dimension": len(vector) == expected_dimension,
}

for name, passed in checks.items():
    print("{}={}".format(name, passed))

if not all(checks.values()):
    raise SystemExit("Direct retrieval validation failed")
PY

pass "Direct retrieval payload is valid"
pass "Stored vector is valid"

header "Semantic Search"

ranking="$(
    python3 - \
        "$OLLAMA_URL" \
        "$QDRANT_URL" \
        "$COLLECTION" \
        "$EMBEDDING_MODEL" \
        "$VECTOR_NAME" <<'PY'
import json
import sys
import urllib.request

ollama_url = sys.argv[1]
qdrant_url = sys.argv[2]
collection = sys.argv[3]
model = sys.argv[4]
vector_name = sys.argv[5]

query_text = (
    "Which service manages agents and orchestrates local AI tasks?"
)


def request_json(url, body):
    request = urllib.request.Request(
        url,
        data=json.dumps(body).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="POST",
    )

    with urllib.request.urlopen(request) as response:
        return json.load(response)


embedding = request_json(
    "{}/api/embed".format(ollama_url),
    {
        "model": model,
        "input": query_text,
    },
)["embeddings"][0]

result = request_json(
    "{}/collections/{}/points/query".format(
        qdrant_url,
        collection,
    ),
    {
        "query": embedding,
        "using": vector_name,
        "limit": 5,
        "with_payload": True,
        "with_vector": False,
    },
)

points = result["result"]["points"]
topics = [
    point.get("payload", {}).get("topic")
    for point in points
]

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

if topics[0] != "openclaw":
    raise SystemExit("OpenClaw did not rank first")

if topics[-1] != "control":
    raise SystemExit("Control passage did not rank last")
PY
)"

printf '%s\n' "$ranking" |
while IFS='|' read -r rank score topic title; do
    printf '%s. score=%s topic=%s title=%s\n' \
        "$rank" "$score" "$topic" "$title"
done

pass "OpenClaw ranked first"
pass "Control passage ranked last"

header "Test Summary"

printf 'Passed: %s\n' "$PASSED"
printf 'Failed: %s\n' "$FAILED"

[[ "$FAILED" -eq 0 ]] || exit 1

printf '\nQdrant persistence validation passed.\n'