#!/usr/bin/env bash
#
# qdrant-test.sh
#
# M04.5 end-to-end smoke test for the Personal AI Server Qdrant deployment.
#
# Validates:
#   - Ollama and Qdrant readiness
#   - versioned collection naming
#   - deterministic UUIDv5 point identity
#   - nomic-embed-text vector dimension
#   - named-vector collection creation
#   - required payload fields
#   - SHA-256 content hashes
#   - UTC RFC 3339 timestamps
#   - point upsert and direct retrieval
#   - semantic ranking
#   - payload filtering
#   - deletion by deterministic UUID
#   - automatic collection cleanup
#
# Compatible with macOS Bash 3.2.
#

set -euo pipefail

readonly OLLAMA_URL="${OLLAMA_URL:-http://127.0.0.1:11434}"
readonly QDRANT_URL="${QDRANT_URL:-http://127.0.0.1:6333}"
readonly EMBEDDING_MODEL="${EMBEDDING_MODEL:-nomic-embed-text:latest}"
readonly EXPECTED_DIMENSION="${EXPECTED_DIMENSION:-768}"
readonly VECTOR_NAME="${VECTOR_NAME:-text-dense}"
readonly COLLECTION_NAME="${COLLECTION_NAME:-validation_m04_v1_test}"
readonly UUID_NAMESPACE="${UUID_NAMESPACE:-b83a8b73-03e0-5f87-a8fb-3f8996cf6f21}"
readonly KEEP_COLLECTION="${KEEP_COLLECTION:-false}"

PASSED=0
FAILED=0
COLLECTION_CREATED=false

print_header() {
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

cleanup() {
    exit_code=$?

    if [[ "$COLLECTION_CREATED" == "true" && "$KEEP_COLLECTION" != "true" ]]; then
        curl \
            --fail \
            --silent \
            --show-error \
            -X DELETE \
            "${QDRANT_URL}/collections/${COLLECTION_NAME}" \
            >/dev/null 2>&1 || true
    fi

    exit "$exit_code"
}

trap cleanup EXIT INT TERM

print_header "Qdrant M04.5 Integration Smoke Test"

require_command curl
require_command python3
require_command grep

printf '\nConfiguration\n'
printf '  Ollama URL         : %s\n' "$OLLAMA_URL"
printf '  Qdrant URL         : %s\n' "$QDRANT_URL"
printf '  Embedding model    : %s\n' "$EMBEDDING_MODEL"
printf '  Expected dimension : %s\n' "$EXPECTED_DIMENSION"
printf '  Vector name        : %s\n' "$VECTOR_NAME"
printf '  Collection         : %s\n' "$COLLECTION_NAME"
printf '  UUID namespace     : %s\n' "$UUID_NAMESPACE"
printf '  Keep collection    : %s\n' "$KEEP_COLLECTION"

print_header "Service Readiness"

if curl --fail --silent --show-error \
    "${OLLAMA_URL}/api/version" >/dev/null
then
    pass "Ollama API is reachable"
else
    fail "Ollama API is not reachable"
    exit 1
fi

if curl --fail --silent --show-error \
    "${QDRANT_URL}/readyz" >/dev/null
then
    pass "Qdrant is ready"
else
    fail "Qdrant is not ready"
    exit 1
fi

print_header "Naming and Identity Contract"

if printf '%s\n' "$COLLECTION_NAME" |
    grep -Eq '^[a-z0-9]+(_[a-z0-9]+)*_v[0-9]+(_test)?$'
then
    pass "Collection name follows the versioned naming convention"
else
    fail "Invalid collection name: ${COLLECTION_NAME}"
    exit 1
fi

identity_output="$(
    python3 - "$UUID_NAMESPACE" <<'PY'
import sys
import uuid

namespace = uuid.UUID(sys.argv[1])


def point_id(source_type, source_id, chunk_id):
    identity = "{}|{}|{}".format(
        source_type,
        source_id,
        chunk_id,
    )
    return str(uuid.uuid5(namespace, identity))


first = point_id(
    "obsidian",
    "Projects/AI Server.md",
    "0003",
)
second = point_id(
    "obsidian",
    "Projects/AI Server.md",
    "0003",
)
different = point_id(
    "obsidian",
    "Projects/AI Server.md",
    "0004",
)

if first != second:
    raise SystemExit("UUIDv5 IDs are not stable")

if first == different:
    raise SystemExit("UUIDv5 IDs are not unique per chunk")

print("first={}".format(first))
print("second={}".format(second))
print("stable={}".format(first == second))
print("different_chunk={}".format(different))
print("unique_per_chunk={}".format(first != different))
PY
)"

printf '%s\n' "$identity_output"
pass "UUIDv5 point IDs are stable"
pass "UUIDv5 point IDs are unique per chunk"

print_header "Embedding Contract"

embedding_dimension="$(
    curl \
        --fail \
        --silent \
        --show-error \
        "${OLLAMA_URL}/api/embed" \
        -H 'Content-Type: application/json' \
        -d "{
          \"model\": \"${EMBEDDING_MODEL}\",
          \"input\": \"M04.5 Qdrant integration smoke test\"
        }" |
    python3 -c '
import json
import sys

data = json.load(sys.stdin)
vectors = data.get("embeddings", [])

if len(vectors) != 1:
    raise SystemExit("Expected exactly one embedding")

print(len(vectors[0]))
'
)"

if [[ "$embedding_dimension" == "$EXPECTED_DIMENSION" ]]; then
    pass "Embedding dimension is ${EXPECTED_DIMENSION}"
else
    fail "Expected dimension ${EXPECTED_DIMENSION}, received ${embedding_dimension}"
    exit 1
fi

print_header "Disposable Collection"

curl \
    --silent \
    --show-error \
    -X DELETE \
    "${QDRANT_URL}/collections/${COLLECTION_NAME}" \
    >/dev/null 2>&1 || true

create_response="$(
    curl \
        --fail \
        --silent \
        --show-error \
        -X PUT \
        "${QDRANT_URL}/collections/${COLLECTION_NAME}" \
        -H 'Content-Type: application/json' \
        -d "{
          \"vectors\": {
            \"${VECTOR_NAME}\": {
              \"size\": ${EXPECTED_DIMENSION},
              \"distance\": \"Cosine\"
            }
          }
        }"
)"

if printf '%s\n' "$create_response" |
    python3 -c '
import json
import sys

data = json.load(sys.stdin)
raise SystemExit(0 if data.get("result") is True else 1)
'
then
    COLLECTION_CREATED=true
    pass "Disposable collection created"
else
    fail "Disposable collection creation failed"
    exit 1
fi

print_header "Point Upsert and Payload Validation"

upsert_output="$(
    python3 - \
        "$OLLAMA_URL" \
        "$QDRANT_URL" \
        "$EMBEDDING_MODEL" \
        "$EXPECTED_DIMENSION" \
        "$VECTOR_NAME" \
        "$COLLECTION_NAME" \
        "$UUID_NAMESPACE" <<'PY'
import hashlib
import json
import re
import sys
import urllib.error
import urllib.request
import uuid
from datetime import datetime, timezone

(
    ollama_url,
    qdrant_url,
    model,
    expected_dimension_text,
    vector_name,
    collection_name,
    namespace_text,
) = sys.argv[1:]

expected_dimension = int(expected_dimension_text)
namespace = uuid.UUID(namespace_text)

documents = [
    {
        "source_id": "ollama-runtime",
        "title": "Ollama Runtime",
        "topic": "ollama",
        "category": "platform",
        "text": (
            "Ollama provides local model inference on the Mac mini. "
            "Its API listens only on 127.0.0.1 port 11434."
        ),
    },
    {
        "source_id": "openclaw-gateway",
        "title": "OpenClaw Gateway",
        "topic": "openclaw",
        "category": "platform",
        "text": (
            "OpenClaw provides the orchestration and agent layer. "
            "Its gateway is managed by launchd and listens on "
            "127.0.0.1 port 18789."
        ),
    },
    {
        "source_id": "docker-startup",
        "title": "Docker Startup",
        "topic": "docker",
        "category": "platform",
        "text": (
            "Docker Desktop starts when the openclaw account logs in. "
            "Containerized services become available after the Docker "
            "engine starts."
        ),
    },
    {
        "source_id": "benchmark-framework",
        "title": "Benchmark Framework",
        "topic": "benchmarks",
        "category": "platform",
        "text": (
            "The benchmark framework evaluates local models using "
            "repeatable workloads, profiles, structured results, and "
            "Markdown or JSON reports."
        ),
    },
    {
        "source_id": "garden-maintenance",
        "title": "Garden Maintenance",
        "topic": "control",
        "category": "control",
        "text": (
            "Tomato plants grow best with regular watering, sunlight, "
            "healthy soil, and protection from garden pests."
        ),
    },
]

required_fields = {
    "schema_version",
    "source_type",
    "source_id",
    "document_id",
    "chunk_id",
    "title",
    "text",
    "content_hash",
    "source_modified_at",
    "indexed_at",
    "embedding_model",
    "embedding_dimension",
}

timestamp_pattern = re.compile(
    r"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$"
)
hash_pattern = re.compile(r"^[0-9a-f]{64}$")


def request_json(url, body=None, method="GET"):
    data = None
    headers = {}

    if body is not None:
        data = json.dumps(body).encode("utf-8")
        headers["Content-Type"] = "application/json"

    request = urllib.request.Request(
        url,
        data=data,
        headers=headers,
        method=method,
    )

    try:
        with urllib.request.urlopen(request) as response:
            return json.load(response)
    except urllib.error.HTTPError as error:
        detail = error.read().decode("utf-8", errors="replace")
        raise RuntimeError(
            "HTTP {} from {}: {}".format(
                error.code,
                url,
                detail,
            )
        ) from error


def normalize_text(text):
    text = text.replace("\r\n", "\n").replace("\r", "\n")
    return "\n".join(
        line.rstrip()
        for line in text.strip().splitlines()
    )


def utc_now():
    return (
        datetime.now(timezone.utc)
        .replace(microsecond=0)
        .isoformat()
        .replace("+00:00", "Z")
    )


def make_document_id(source_type, source_id):
    identity = "{}|{}".format(source_type, source_id)
    return str(uuid.uuid5(namespace, identity))


def make_point_id(source_type, source_id, chunk_id):
    identity = "{}|{}|{}".format(
        source_type,
        source_id,
        chunk_id,
    )
    return str(uuid.uuid5(namespace, identity))


source_type = "validation"
chunk_id = "0001"
source_modified_at = utc_now()
indexed_at = utc_now()

for document in documents:
    document["text"] = normalize_text(document["text"])

embedding_result = request_json(
    "{}/api/embed".format(ollama_url),
    {
        "model": model,
        "input": [
            document["text"]
            for document in documents
        ],
    },
    method="POST",
)

vectors = embedding_result.get("embeddings", [])

if len(vectors) != len(documents):
    raise SystemExit(
        "Expected {} embeddings, received {}".format(
            len(documents),
            len(vectors),
        )
    )

dimensions = {len(vector) for vector in vectors}

if dimensions != {expected_dimension}:
    raise SystemExit(
        "Unexpected vector dimensions: {}".format(
            sorted(dimensions)
        )
    )

points = []

for document, vector in zip(documents, vectors):
    normalized_text = document["text"]
    content_hash = hashlib.sha256(
        normalized_text.encode("utf-8")
    ).hexdigest()

    payload = {
        "schema_version": 1,
        "source_type": source_type,
        "source_id": document["source_id"],
        "document_id": make_document_id(
            source_type,
            document["source_id"],
        ),
        "chunk_id": chunk_id,
        "title": document["title"],
        "text": normalized_text,
        "content_hash": content_hash,
        "source_modified_at": source_modified_at,
        "indexed_at": indexed_at,
        "embedding_model": model,
        "embedding_dimension": len(vector),
        "topic": document["topic"],
        "category": document["category"],
    }

    missing = required_fields.difference(payload)

    if missing:
        raise SystemExit(
            "Payload missing required fields: {}".format(
                sorted(missing)
            )
        )

    uuid.UUID(payload["document_id"])

    if not hash_pattern.fullmatch(payload["content_hash"]):
        raise SystemExit("Invalid SHA-256 content hash")

    if not timestamp_pattern.fullmatch(
        payload["source_modified_at"]
    ):
        raise SystemExit(
            "Invalid source_modified_at timestamp"
        )

    if not timestamp_pattern.fullmatch(payload["indexed_at"]):
        raise SystemExit("Invalid indexed_at timestamp")

    points.append(
        {
            "id": make_point_id(
                source_type,
                document["source_id"],
                chunk_id,
            ),
            "vector": {
                vector_name: vector,
            },
            "payload": payload,
        }
    )

upsert_result = request_json(
    "{}/collections/{}/points?wait=true".format(
        qdrant_url,
        collection_name,
    ),
    {
        "points": points,
    },
    method="PUT",
)

operation = upsert_result.get("result", {})

if operation.get("status") != "completed":
    raise SystemExit(
        "Point upsert did not complete: {}".format(
            upsert_result
        )
    )

collection_result = request_json(
    "{}/collections/{}".format(
        qdrant_url,
        collection_name,
    )
)

point_count = (
    collection_result
    .get("result", {})
    .get("points_count")
)

if point_count != len(documents):
    raise SystemExit(
        "Expected {} points, found {}".format(
            len(documents),
            point_count,
        )
    )

openclaw_point_id = make_point_id(
    source_type,
    "openclaw-gateway",
    chunk_id,
)

point_result = request_json(
    "{}/collections/{}/points/{}".format(
        qdrant_url,
        collection_name,
        openclaw_point_id,
    )
)

point = point_result.get("result", {})
payload = point.get("payload", {})
stored_vector = (
    point
    .get("vector", {})
    .get(vector_name, [])
)

if payload.get("topic") != "openclaw":
    raise SystemExit(
        "Direct retrieval returned the wrong point"
    )

missing = required_fields.difference(payload)

if missing:
    raise SystemExit(
        "Retrieved payload is missing fields: {}".format(
            sorted(missing)
        )
    )

expected_hash = hashlib.sha256(
    payload["text"].encode("utf-8")
).hexdigest()

if payload.get("content_hash") != expected_hash:
    raise SystemExit(
        "Retrieved content hash does not match text"
    )

if len(stored_vector) != expected_dimension:
    raise SystemExit(
        "Retrieved vector dimension is incorrect"
    )

print("POINTS_UPSERTED={}".format(len(points)))
print("OPENCLAW_POINT_ID={}".format(openclaw_point_id))
print("DIRECT_RETRIEVAL_TOPIC=openclaw")
print("REQUIRED_FIELDS_VALID=true")
print("CONTENT_HASH_VALID=true")
print("TIMESTAMPS_VALID=true")
PY
)"

printf '%s\n' "$upsert_output"
pass "Five validation points upserted with UUIDv5 IDs"
pass "Direct retrieval returned the OpenClaw point"
pass "All required payload fields are present"
pass "SHA-256 content hashes are valid"
pass "UTC RFC 3339 timestamps are valid"

print_header "Semantic Ranking"

ranking_output="$(
    python3 - \
        "$OLLAMA_URL" \
        "$QDRANT_URL" \
        "$EMBEDDING_MODEL" \
        "$VECTOR_NAME" \
        "$COLLECTION_NAME" <<'PY'
import json
import sys
import urllib.request

(
    ollama_url,
    qdrant_url,
    model,
    vector_name,
    collection_name,
) = sys.argv[1:]

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


embedding_result = request_json(
    "{}/api/embed".format(ollama_url),
    {
        "model": model,
        "input": query_text,
    },
)

vectors = embedding_result.get("embeddings", [])

if len(vectors) != 1:
    raise SystemExit("Expected one query embedding")

query_result = request_json(
    "{}/collections/{}/points/query".format(
        qdrant_url,
        collection_name,
    ),
    {
        "query": vectors[0],
        "using": vector_name,
        "limit": 5,
        "with_payload": True,
        "with_vector": False,
    },
)

points = query_result.get("result", {}).get("points", [])

if len(points) != 5:
    raise SystemExit(
        "Expected five query results, received {}".format(
            len(points)
        )
    )

topics = [
    point.get("payload", {}).get("topic")
    for point in points
]

if topics[0] != "openclaw":
    raise SystemExit(
        "Expected openclaw first; ordering was {}".format(
            topics
        )
    )

if topics[-1] != "control":
    raise SystemExit(
        "Expected control last; ordering was {}".format(
            topics
        )
    )

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

pass "OpenClaw ranked first"
pass "Unrelated control passage ranked last"

print_header "Payload Filtering"

filter_topic="$(
    python3 - \
        "$OLLAMA_URL" \
        "$QDRANT_URL" \
        "$EMBEDDING_MODEL" \
        "$VECTOR_NAME" \
        "$COLLECTION_NAME" <<'PY'
import json
import sys
import urllib.request

(
    ollama_url,
    qdrant_url,
    model,
    vector_name,
    collection_name,
) = sys.argv[1:]


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
    {
        "model": model,
        "input": "How does the local AI platform operate?",
    },
)

vectors = embedding_result.get("embeddings", [])

if len(vectors) != 1:
    raise SystemExit(
        "Expected one filter-query embedding"
    )

query_result = request_json(
    "{}/collections/{}/points/query".format(
        qdrant_url,
        collection_name,
    ),
    {
        "query": vectors[0],
        "using": vector_name,
        "filter": {
            "must": [
                {
                    "key": "category",
                    "match": {
                        "value": "control",
                    },
                }
            ]
        },
        "limit": 5,
        "with_payload": True,
        "with_vector": False,
    },
)

points = query_result.get("result", {}).get("points", [])

if len(points) != 1:
    raise SystemExit(
        "Expected one filtered result, received {}".format(
            len(points)
        )
    )

topic = points[0].get("payload", {}).get("topic")

if topic != "control":
    raise SystemExit(
        "Expected control topic, received {}".format(
            topic
        )
    )

print(topic)
PY
)"

if [[ "$filter_topic" == "control" ]]; then
    pass "Payload filter returned only the control document"
else
    fail "Payload filtering returned unexpected topic: ${filter_topic}"
    exit 1
fi

print_header "Point Deletion"

control_point_id="$(
    python3 - "$UUID_NAMESPACE" <<'PY'
import sys
import uuid

namespace = uuid.UUID(sys.argv[1])
identity = "validation|garden-maintenance|0001"
print(uuid.uuid5(namespace, identity))
PY
)"

delete_response="$(
    curl \
        --fail \
        --silent \
        --show-error \
        -X POST \
        "${QDRANT_URL}/collections/${COLLECTION_NAME}/points/delete?wait=true" \
        -H 'Content-Type: application/json' \
        -d "{\"points\":[\"${control_point_id}\"]}"
)"

if printf '%s\n' "$delete_response" |
    python3 -c '
import json
import sys

data = json.load(sys.stdin)
status = data.get("result", {}).get("status")
raise SystemExit(0 if status == "completed" else 1)
'
then
    pass "Control point deleted by deterministic UUID"
else
    fail "Control point deletion failed"
    exit 1
fi

remaining_points="$(
    curl \
        --fail \
        --silent \
        --show-error \
        "${QDRANT_URL}/collections/${COLLECTION_NAME}" |
    python3 -c '
import json
import sys

data = json.load(sys.stdin)
print(data["result"]["points_count"])
'
)"

if [[ "$remaining_points" == "4" ]]; then
    pass "Point count decreased to four"
else
    fail "Expected four remaining points, found ${remaining_points}"
    exit 1
fi

print_header "Test Summary"

printf 'Passed: %s\n' "$PASSED"
printf 'Failed: %s\n' "$FAILED"

if [[ "$KEEP_COLLECTION" == "true" ]]; then
    printf 'Collection retained: %s\n' "$COLLECTION_NAME"
else
    printf 'Collection cleanup: scheduled\n'
fi

if [[ "$FAILED" -ne 0 ]]; then
    exit 1
fi

printf '\nAll Qdrant M04.5 integration tests passed.\n'
