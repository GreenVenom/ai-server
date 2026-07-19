#!/bin/bash

set -u

SERVER_ROOT="${HOME}/server"
PYTHON_BIN="${SERVER_ROOT}/services/obsidian/venv/bin/python"
SOURCE_ROOT="${SERVER_ROOT}/services/obsidian/src"

passed=0
failed=0

pass() {
    passed=$((passed + 1))
    printf 'PASS: %s\n' "$1"
}

fail() {
    failed=$((failed + 1))
    printf 'FAIL: %s\n' "$1" >&2
}

run_test() {
    description="$1"
    code="$2"

    if PYTHONPATH="${SOURCE_ROOT}" \
        "${PYTHON_BIN}" -c "${code}"
    then
        pass "${description}"
    else
        fail "${description}"
    fi
}

run_test \
    "Search module loads" \
    'from obsidian_ingest import search'

run_test \
    "Qdrant backup result ranks first" \
    '
from obsidian_ingest.search import semantic_search

results = semantic_search(
    "How are Qdrant backups and snapshots handled?",
    vault_id="m05-fixture",
    limit=5,
)

assert results
assert results[0].relative_path == "nested/Qdrant Operations.md"
assert results[0].heading == "Backup and Restore"
'

run_test \
    "AI orchestration result appears in top three" \
    '
from obsidian_ingest.search import semantic_search

results = semantic_search(
    "Which component provides AI orchestration?",
    vault_id="m05-fixture",
    limit=5,
)

matches = [
    index
    for index, result in enumerate(results, start=1)
    if (
        result.relative_path == "basic/Platform Overview.md"
        and result.heading == "Runtime Components"
    )
]

assert matches
assert matches[0] <= 3
'

run_test \
    "Docker startup result ranks first" \
    '
from obsidian_ingest.search import semantic_search

results = semantic_search(
    "When does Docker Desktop start?",
    vault_id="m05-fixture",
    limit=5,
)

assert results
assert results[0].relative_path == "basic/Docker Startup.md"
'

run_test \
    "Tag filtering returns only qdrant notes" \
    '
from obsidian_ingest.search import semantic_search

results = semantic_search(
    "How is the vector database deployed?",
    vault_id="m05-fixture",
    tag="qdrant",
    limit=5,
)

assert results
assert all(
    result.relative_path == "nested/Qdrant Operations.md"
    for result in results
)
'

run_test \
    "Deployment result appears in top three" \
    '
from obsidian_ingest.search import semantic_search

results = semantic_search(
    "How is the vector database deployed?",
    vault_id="m05-fixture",
    tag="qdrant",
    limit=5,
)

matches = [
    index
    for index, result in enumerate(results, start=1)
    if result.heading == "Deployment"
]

assert matches
assert matches[0] <= 3
'

run_test \
    "Excluded note never appears in retrieval" \
    '
from obsidian_ingest.search import semantic_search

results = semantic_search(
    "This fixture must never appear in retrieval results",
    vault_id="m05-fixture",
    limit=8,
)

assert all(
    result.relative_path != "excluded/Private Note.md"
    for result in results
)
'

run_test \
    "Vault filter is enforced" \
    '
from obsidian_ingest.search import semantic_search

results = semantic_search(
    "Qdrant",
    vault_id="nonexistent-vault",
    limit=5,
)

assert results == ()
'

run_test \
    "Search results include traceable source metadata" \
    '
from obsidian_ingest.search import semantic_search

results = semantic_search(
    "Docker startup",
    vault_id="m05-fixture",
    limit=3,
)

assert results

for result in results:
    assert result.title
    assert result.relative_path
    assert result.document_id
    assert result.chunk_id
    assert result.chunk_text
'

printf '\nPassed: %d\n' "${passed}"
printf 'Failed: %d\n' "${failed}"

if [[ "${failed}" -ne 0 ]]; then
    exit 1
fi

exit 0