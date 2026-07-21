"""Unit tests for read-only collection inspection."""

from __future__ import annotations

from unittest.mock import patch

from personal_ai_mcp.obsidian.collection import scroll_all_payloads


def test_scroll_all_payloads_handles_pagination() -> None:
    responses = [
        {
            "result": {
                "points": [{"id": "one"}],
                "next_page_offset": "next",
            }
        },
        {
            "result": {
                "points": [{"id": "two"}],
                "next_page_offset": None,
            }
        },
    ]

    with patch(
        "personal_ai_mcp.obsidian.collection._request_json",
        side_effect=responses,
    ) as request:
        points = scroll_all_payloads("obsidian_chunks_v1")

    assert [point["id"] for point in points] == [
        "one",
        "two",
    ]

    assert request.call_count == 2

    second_payload = request.call_args_list[1].kwargs["payload"]

    assert second_payload["offset"] == "next"