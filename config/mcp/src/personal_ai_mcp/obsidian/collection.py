"""Read-only Qdrant inspection helpers for Obsidian MCP tools."""

from __future__ import annotations

import json
import urllib.error
import urllib.request
from typing import Any

from personal_ai_mcp.common.errors import DependencyError


QDRANT_URL = "http://127.0.0.1:6333"
SCROLL_PAGE_SIZE = 256


def _request_json(
    url: str,
    *,
    payload: dict[str, Any] | None = None,
) -> dict[str, Any]:
    data = None
    method = "GET"

    if payload is not None:
        data = json.dumps(payload).encode("utf-8")
        method = "POST"

    request = urllib.request.Request(
        url,
        data=data,
        headers={"Content-Type": "application/json"},
        method=method,
    )

    try:
        with urllib.request.urlopen(
            request,
            timeout=10,
        ) as response:
            result = json.load(response)
    except (
        OSError,
        urllib.error.URLError,
        json.JSONDecodeError,
    ) as exc:
        raise DependencyError(
            "The Obsidian vector store is unavailable."
        ) from exc

    if not isinstance(result, dict):
        raise DependencyError(
            "The Obsidian vector store returned an invalid response."
        )

    return result


def collection_info(collection: str) -> dict[str, Any]:
    response = _request_json(
        f"{QDRANT_URL}/collections/{collection}"
    )

    result = response.get("result")

    if not isinstance(result, dict):
        raise DependencyError(
            "The Obsidian collection status is unavailable."
        )

    return result


def scroll_all_payloads(
    collection: str,
) -> list[dict[str, Any]]:
    points: list[dict[str, Any]] = []
    offset: str | int | None = None

    while True:
        payload: dict[str, Any] = {
            "limit": SCROLL_PAGE_SIZE,
            "with_payload": True,
            "with_vector": False,
        }

        if offset is not None:
            payload["offset"] = offset

        response = _request_json(
            f"{QDRANT_URL}/collections/"
            f"{collection}/points/scroll",
            payload=payload,
        )

        result = response.get("result")

        if not isinstance(result, dict):
            raise DependencyError(
                "The Obsidian point inventory is unavailable."
            )

        page = result.get("points", [])

        if not isinstance(page, list):
            raise DependencyError(
                "The Obsidian point inventory is invalid."
            )

        points.extend(
            point
            for point in page
            if isinstance(point, dict)
        )

        offset = result.get("next_page_offset")

        if offset is None:
            break

    return points


def retrieve_point(
    collection: str,
    point_id: str,
) -> dict[str, Any] | None:
    response = _request_json(
        f"{QDRANT_URL}/collections/"
        f"{collection}/points",
        payload={
            "ids": [point_id],
            "with_payload": True,
            "with_vector": False,
        },
    )

    result = response.get("result")

    if not isinstance(result, list):
        raise DependencyError(
            "The Obsidian point response is invalid."
        )

    if not result:
        return None

    point = result[0]

    if not isinstance(point, dict):
        raise DependencyError(
            "The Obsidian point response is invalid."
        )

    return point