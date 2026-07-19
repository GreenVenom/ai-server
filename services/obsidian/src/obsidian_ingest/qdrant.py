#!/usr/bin/env python3

"""Minimal Qdrant REST client for Obsidian indexing."""

from __future__ import annotations

import json
import urllib.error
import urllib.parse
import urllib.request
from typing import Any, Mapping, Sequence


DEFAULT_QDRANT_URL = "http://127.0.0.1:6333"
DEFAULT_COLLECTION = "obsidian_chunks_v1"
VECTOR_NAME = "text-dense"
VECTOR_DIMENSION = 768


class QdrantError(RuntimeError):
    """Raised when a Qdrant operation fails."""


def _request_json(
    path: str,
    *,
    method: str = "GET",
    payload: Mapping[str, Any] | None = None,
    base_url: str = DEFAULT_QDRANT_URL,
    timeout_seconds: int = 120,
) -> Mapping[str, Any]:
    body = None

    if payload is not None:
        body = json.dumps(payload).encode("utf-8")

    request = urllib.request.Request(
        f"{base_url.rstrip('/')}{path}",
        data=body,
        method=method,
        headers={
            "Content-Type": "application/json",
        },
    )

    try:
        with urllib.request.urlopen(
            request,
            timeout=timeout_seconds,
        ) as response:
            data = json.load(response)
    except urllib.error.HTTPError as exc:
        error_body = exc.read().decode("utf-8", errors="replace")
        raise QdrantError(
            f"Qdrant request failed: "
            f"{method} {path}: HTTP {exc.code}: {error_body}"
        ) from exc
    except urllib.error.URLError as exc:
        raise QdrantError(
            f"Unable to reach Qdrant: {exc}"
        ) from exc
    except TimeoutError as exc:
        raise QdrantError(
            f"Qdrant request timed out: {method} {path}"
        ) from exc

    if data.get("status") not in {"ok", None}:
        raise QdrantError(
            f"Qdrant returned a failure response: {data}"
        )

    return data


def collection_info(
    collection: str = DEFAULT_COLLECTION,
) -> Mapping[str, Any]:
    encoded = urllib.parse.quote(collection, safe="")

    return _request_json(
        f"/collections/{encoded}"
    )


def validate_collection(
    collection: str = DEFAULT_COLLECTION,
) -> None:
    data = collection_info(collection)
    result = data["result"]
    vectors = result["config"]["params"]["vectors"]
    vector = vectors[VECTOR_NAME]

    if vector["size"] != VECTOR_DIMENSION:
        raise QdrantError(
            "Collection dimension mismatch: "
            f"expected={VECTOR_DIMENSION}, actual={vector['size']}"
        )

    if vector["distance"] != "Cosine":
        raise QdrantError(
            f"Collection distance mismatch: {vector['distance']}"
        )


def upsert_points(
    points: Sequence[Mapping[str, Any]],
    *,
    collection: str = DEFAULT_COLLECTION,
    wait: bool = True,
) -> Mapping[str, Any]:
    if not points:
        raise QdrantError("At least one point is required")

    encoded = urllib.parse.quote(collection, safe="")
    wait_value = "true" if wait else "false"

    return _request_json(
        f"/collections/{encoded}/points?wait={wait_value}",
        method="PUT",
        payload={
            "points": list(points),
        },
    )


def count_points(
    collection: str = DEFAULT_COLLECTION,
) -> int:
    encoded = urllib.parse.quote(collection, safe="")

    data = _request_json(
        f"/collections/{encoded}/points/count",
        method="POST",
        payload={
            "exact": True,
        },
    )

    return int(data["result"]["count"])


def delete_points(
    point_ids: Sequence[str],
    *,
    collection: str = DEFAULT_COLLECTION,
    wait: bool = True,
) -> Mapping[str, Any]:
    if not point_ids:
        raise QdrantError("At least one point ID is required")

    encoded = urllib.parse.quote(collection, safe="")
    wait_value = "true" if wait else "false"

    return _request_json(
        f"/collections/{encoded}/points/delete?wait={wait_value}",
        method="POST",
        payload={
            "points": list(point_ids),
        },
    )


def query_points(
    vector: Sequence[float],
    *,
    collection: str = DEFAULT_COLLECTION,
    limit: int = 5,
    score_threshold: float | None = None,
    query_filter: Mapping[str, Any] | None = None,
) -> Sequence[Mapping[str, Any]]:
    if not vector:
        raise QdrantError("Query vector cannot be empty")

    if len(vector) != VECTOR_DIMENSION:
        raise QdrantError(
            "Query vector dimension mismatch: "
            f"expected={VECTOR_DIMENSION}, actual={len(vector)}"
        )

    if limit <= 0:
        raise QdrantError("Search limit must be positive")

    encoded = urllib.parse.quote(collection, safe="")

    payload: dict[str, Any] = {
        "query": list(vector),
        "using": VECTOR_NAME,
        "limit": limit,
        "with_payload": True,
        "with_vector": False,
    }

    if score_threshold is not None:
        payload["score_threshold"] = score_threshold

    if query_filter is not None:
        payload["filter"] = query_filter

    data = _request_json(
        f"/collections/{encoded}/points/query",
        method="POST",
        payload=payload,
    )

    result = data.get("result", {})
    points = result.get("points", [])

    if not isinstance(points, list):
        raise QdrantError(
            "Qdrant query response did not contain a point list"
        )

    return tuple(points)