#!/bin/bash

set -u

SCRIPT_NAME="test-obsidian-chunking.sh"

SERVER_ROOT="${HOME}/server"
PYTHON_BIN="${SERVER_ROOT}/services/obsidian/venv/bin/python"
SOURCE_ROOT="${SERVER_ROOT}/services/obsidian/src"
FIXTURE_ROOT="${SERVER_ROOT}/scripts/tests/fixtures/obsidian"
VAULT_ID="m05-fixture"

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

run_python_test() {
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

if [[ -x "${PYTHON_BIN}" ]]; then
    pass "Obsidian Python environment exists"
else
    fail "Obsidian Python environment exists"
fi

if [[ -d "${SOURCE_ROOT}/obsidian_ingest" ]]; then
    pass "Obsidian source package exists"
else
    fail "Obsidian source package exists"
fi

run_python_test \
    "Identity module loads" \
    'from obsidian_ingest import identity'

run_python_test \
    "Chunking module loads" \
    'from obsidian_ingest import chunking'

run_python_test \
    "Document identity is deterministic" \
    '
from obsidian_ingest.identity import document_id

first = document_id("m05-fixture", "basic/Platform Overview.md")
second = document_id("m05-fixture", "basic/Platform Overview.md")

assert first == second
'

run_python_test \
    "Vault identities remain isolated" \
    '
from obsidian_ingest.identity import document_id

first = document_id("m05-fixture", "basic/Platform Overview.md")
second = document_id("another-vault", "basic/Platform Overview.md")

assert first != second
'

run_python_test \
    "Platform fixture creates three chunks" \
    "
from pathlib import Path

from obsidian_ingest.chunking import chunk_document
from obsidian_ingest.parser import parse_document

root = Path('${FIXTURE_ROOT}')
path = root / 'basic/Platform Overview.md'

document = parse_document(path, root=root)
chunks = chunk_document(document, vault_id='${VAULT_ID}')

assert len(chunks) == 3
"

run_python_test \
    "Qdrant fixture omits empty top-level section" \
    "
from pathlib import Path

from obsidian_ingest.chunking import chunk_document
from obsidian_ingest.parser import parse_document

root = Path('${FIXTURE_ROOT}')
path = root / 'nested/Qdrant Operations.md'

document = parse_document(path, root=root)
chunks = chunk_document(document, vault_id='${VAULT_ID}')

assert len(chunks) == 2
assert [chunk.heading for chunk in chunks] == [
    'Deployment',
    'Backup and Restore',
]
"

run_python_test \
    "Excluded fixture creates no chunks" \
    "
from pathlib import Path

from obsidian_ingest.chunking import chunk_document
from obsidian_ingest.parser import parse_document

root = Path('${FIXTURE_ROOT}')
path = root / 'excluded/Private Note.md'

document = parse_document(path, root=root)
chunks = chunk_document(document, vault_id='${VAULT_ID}')

assert not chunks
"

run_python_test \
    "Malformed fixture creates no chunks" \
    "
from pathlib import Path

from obsidian_ingest.chunking import chunk_document
from obsidian_ingest.parser import parse_document

root = Path('${FIXTURE_ROOT}')
path = root / 'malformed/Broken Frontmatter.md'

document = parse_document(path, root=root)
chunks = chunk_document(document, vault_id='${VAULT_ID}')

assert not chunks
"

run_python_test \
    "Empty fixture creates no chunks" \
    "
from pathlib import Path

from obsidian_ingest.chunking import chunk_document
from obsidian_ingest.parser import parse_document

root = Path('${FIXTURE_ROOT}')
path = root / 'basic/Empty Note.md'

document = parse_document(path, root=root)
chunks = chunk_document(document, vault_id='${VAULT_ID}')

assert not chunks
"

run_python_test \
    "Chunk IDs and hashes repeat deterministically" \
    "
from pathlib import Path

from obsidian_ingest.chunking import chunk_document
from obsidian_ingest.parser import parse_document

root = Path('${FIXTURE_ROOT}')
path = root / 'basic/Platform Overview.md'

first = chunk_document(
    parse_document(path, root=root),
    vault_id='${VAULT_ID}',
)

second = chunk_document(
    parse_document(path, root=root),
    vault_id='${VAULT_ID}',
)

assert [item.chunk_id for item in first] == [
    item.chunk_id for item in second
]

assert [item.content_hash for item in first] == [
    item.content_hash for item in second
]
"

run_python_test \
    "Chunk IDs are unique within a document" \
    "
from pathlib import Path

from obsidian_ingest.chunking import chunk_document
from obsidian_ingest.parser import parse_document

root = Path('${FIXTURE_ROOT}')
path = root / 'basic/Platform Overview.md'

chunks = chunk_document(
    parse_document(path, root=root),
    vault_id='${VAULT_ID}',
)

ids = [item.chunk_id for item in chunks]

assert len(ids) == len(set(ids))
"

run_python_test \
    "Oversized chunks respect maximum size" \
    "
from pathlib import Path

from obsidian_ingest.chunking import ChunkingConfig, chunk_document
from obsidian_ingest.parser import parse_document

root = Path('${FIXTURE_ROOT}')
path = root / 'basic/Oversized Note.md'

config = ChunkingConfig(
    target_tokens=200,
    maximum_tokens=260,
    overlap_tokens=30,
    minimum_tokens=20,
)

chunks = chunk_document(
    parse_document(path, root=root),
    vault_id='${VAULT_ID}',
    config=config,
)

assert chunks
assert all(
    item.token_count <= config.maximum_tokens
    for item in chunks
)
"

printf '\nPassed: %d\n' "${passed}"
printf 'Failed: %d\n' "${failed}"

if [[ "${failed}" -ne 0 ]]; then
    exit 1
fi

exit 0