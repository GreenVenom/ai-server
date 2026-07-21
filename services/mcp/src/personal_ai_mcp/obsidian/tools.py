import json
import urllib.request
from pathlib import Path
from typing import Any
from personal_ai_mcp.common.errors import (
    AuthorizationError,
    DependencyError,
    ValidationError,
)
from personal_ai_mcp.common.models import success
from personal_ai_mcp.common.validation import validate_safe_id
from .schemas import SearchRequest, GetChunkRequest, VaultRequest

QDRANT_URL = "http://127.0.0.1:6333"
OLLAMA_URL = "http://127.0.0.1:11434"
COLLECTION = "obsidian_chunks_v1"
EMBEDDING_MODEL = "nomic-embed-text:latest"
APPROVED_VAULTS = {"personal-knowledge"}
MANIFEST_DIR = Path.home() / "server/data/obsidian/manifests"

def _post(url: str, payload: dict[str, Any]) -> dict[str, Any]:
    request = urllib.request.Request(
        url,
        data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            return json.load(response)
    except Exception as exc:
        raise DependencyError(
            "A local retrieval dependency is unavailable."
        ) from exc

def _approve_vault(vault_id: str) -> str:
    validate_safe_id(vault_id, "vault_id")
    if vault_id not in APPROVED_VAULTS:
        raise AuthorizationError(
            "The requested vault is not approved for retrieval."
        )
    return vault_id

def _embed(query: str) -> list[float]:
    response = _post(
        f"{OLLAMA_URL}/api/embed",
        {"model": EMBEDDING_MODEL, "input": query},
    )
    return response["embeddings"][0]

def obsidian_list_vaults_tool() -> dict[str, Any]:
    return success({
        "vaults": [
            {"vault_id": vault, "access": "read-only"}
            for vault in sorted(APPROVED_VAULTS)
        ]
    })

def obsidian_search_tool(
    vault_id: str,
    query: str,
    limit: int = 5,
) -> dict[str, Any]:
    request = SearchRequest(
        vault_id=vault_id,
        query=query,
        limit=limit,
    )
    _approve_vault(request.vault_id)
    if not request.query.strip() or not 1 <= request.limit <= 20:
        raise ValidationError("Search query or limit is invalid.")

    response = _post(
        f"{QDRANT_URL}/collections/{COLLECTION}/points/query",
        {
            "query": _embed(request.query),
            "using": "text-dense",
            "limit": request.limit,
            "with_payload": True,
            "filter": {
                "must": [{
                    "key": "vault_id",
                    "match": {"value": request.vault_id},
                }]
            },
        },
    )
    points = response["result"]["points"]
    return success({
        "vault_id": request.vault_id,
        "query": request.query,
        "results": [{
            "id": item["id"],
            "score": item.get("score"),
            "payload": item.get("payload", {}),
        } for item in points],
    })

def obsidian_get_chunk_tool(
    vault_id: str,
    chunk_id: str,
) -> dict[str, Any]:
    request = GetChunkRequest(
        vault_id=vault_id,
        chunk_id=chunk_id,
    )
    _approve_vault(request.vault_id)
    validate_safe_id(request.chunk_id, "chunk_id")

    response = _post(
        f"{QDRANT_URL}/collections/{COLLECTION}/points",
        {
            "ids": [request.chunk_id],
            "with_payload": True,
            "with_vector": False,
        },
    )
    points = response.get("result", [])
    if (
        not points
        or points[0].get("payload", {}).get("vault_id")
        != request.vault_id
    ):
        raise AuthorizationError(
            "The requested chunk is unavailable in the approved vault."
        )
    return success({
        "vault_id": request.vault_id,
        "chunk": points[0],
    })

def obsidian_retrieval_status_tool(
    vault_id: str,
) -> dict[str, Any]:
    request = VaultRequest(vault_id=vault_id)
    _approve_vault(request.vault_id)

    manifest_path = MANIFEST_DIR / f"{request.vault_id}.json"
    try:
        manifest = json.loads(manifest_path.read_text())
    except Exception as exc:
        raise DependencyError(
            "The approved vault manifest is unavailable."
        ) from exc

    documents = manifest.get("documents", {})
    chunk_ids = {
        chunk
        for document in documents.values()
        for chunk in document.get("chunk_ids", [])
    }

    response = _post(
        f"{QDRANT_URL}/collections/{COLLECTION}/points/scroll",
        {
            "limit": 10000,
            "with_payload": True,
            "with_vector": False,
            "filter": {
                "must": [{
                    "key": "vault_id",
                    "match": {"value": request.vault_id},
                }]
            },
        },
    )
    points = response["result"]["points"]
    qdrant_ids = {point["id"] for point in points}
    vault_ids = {
        point.get("payload", {}).get("vault_id")
        for point in points
    }

    return success({
        "vault_id": request.vault_id,
        "documents": len(documents),
        "chunks": len(chunk_ids),
        "reconciled": chunk_ids == qdrant_ids,
        "missing_points": len(chunk_ids - qdrant_ids),
        "orphan_points": len(qdrant_ids - chunk_ids),
        "unapproved_vault_ids": sorted(
            value
            for value in vault_ids
            if value not in APPROVED_VAULTS
        ),
    })
