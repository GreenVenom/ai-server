"""Live production-collection integrity checks."""

from __future__ import annotations

import json
import urllib.request

import pytest


COLLECTION = "obsidian_chunks_v1"
QDRANT_URL = "http://127.0.0.1:6333"


def scroll_points() -> list[dict]:
    request = urllib.request.Request(
        f"{QDRANT_URL}/collections/{COLLECTION}/points/scroll",
        data=json.dumps(
            {
                "limit": 256,
                "with_payload": True,
                "with_vector": False,
            }
        ).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="POST",
    )

    with urllib.request.urlopen(
        request,
        timeout=10,
    ) as response:
        return json.load(response)["result"]["points"]


@pytest.mark.integration
def test_production_collection_contains_no_fixture_paths() -> None:
    points = scroll_points()

    fixture_paths = [
        str(point.get("payload", {}).get("relative_path", ""))
        for point in points
        if str(
            point.get("payload", {}).get("relative_path", "")
        ).startswith(("basic/", "nested/"))
    ]

    assert fixture_paths == []


@pytest.mark.integration
def test_production_collection_matches_expected_point_count() -> None:
    points = scroll_points()

    assert len(points) == 176