"""Thin subprocess adapter around the M05 retrieval boundary."""

from __future__ import annotations

import json
import os
import subprocess
from dataclasses import dataclass
from typing import Any

from personal_ai_mcp.common.errors import (
    DependencyError,
    ObsidianRetrievalError,
    ToolTimeoutError,
)
from personal_ai_mcp.common.limits import (
    MAX_CHUNK_TEXT_LENGTH,
    MAX_TOTAL_RESULT_TEXT_LENGTH,
)
from personal_ai_mcp.obsidian.config import (
    ObsidianMCPConfig,
    VaultConfig,
    load_config,
)
from personal_ai_mcp.obsidian.schemas import SearchRequest


@dataclass(frozen=True, slots=True)
class SearchExecution:
    """Validated result returned by the M05 retrieval boundary."""

    payload: dict[str, Any]
    command_duration_ms: int | None = None


def _safe_environment(pythonpath: str) -> dict[str, str]:
    """Create the minimum controlled environment needed by M05."""
    environment = {
        "HOME": os.environ.get("HOME", "/Users/openclaw"),
        "PATH": "/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:/opt/homebrew/bin",
        "PYTHONPATH": pythonpath,
        "LANG": os.environ.get("LANG", "en_US.UTF-8"),
    }

    return environment


def _build_search_command(
    request: SearchRequest,
    *,
    config: ObsidianMCPConfig,
    vault: VaultConfig,
) -> list[str]:
    command = [
        config.runtime.executable,
        "-m",
        config.runtime.module,
        request.query,
        "--vault-id",
        vault.vault_id,
        "--collection",
        vault.collection,
        "--limit",
        str(request.limit),
    ]

    if request.score_threshold is not None:
        command.extend(
            [
                "--score-threshold",
                str(request.score_threshold),
            ]
        )

    if request.tag is not None:
        command.extend(["--tag", request.tag])

    if request.relative_path is not None:
        command.extend(
            ["--relative-path", request.relative_path]
        )

    return command


def _parse_error(stderr: str) -> str:
    """Extract a safe error message from the M05 JSON error."""
    try:
        payload = json.loads(stderr)
    except json.JSONDecodeError:
        return "The Obsidian retrieval dependency failed."

    error = payload.get("error")

    if not isinstance(error, dict):
        return "The Obsidian retrieval dependency failed."

    message = error.get("message")

    if not isinstance(message, str) or not message.strip():
        return "The Obsidian retrieval dependency failed."

    return message.strip()[:500]


def _bound_results(payload: dict[str, Any]) -> dict[str, Any]:
    """Enforce MCP output limits without modifying source systems."""
    raw_results = payload.get("results", [])

    if not isinstance(raw_results, list):
        raise ObsidianRetrievalError(
            "The Obsidian retrieval response is invalid."
        )

    bounded_results: list[dict[str, Any]] = []
    total_text_length = 0

    for item in raw_results:
        if not isinstance(item, dict):
            raise ObsidianRetrievalError(
                "The Obsidian retrieval response is invalid."
            )

        bounded = dict(item)
        text = str(bounded.get("chunk_text", ""))

        remaining = (
            MAX_TOTAL_RESULT_TEXT_LENGTH
            - total_text_length
        )

        if remaining <= 0:
            break

        maximum = min(
            MAX_CHUNK_TEXT_LENGTH,
            remaining,
        )

        bounded["chunk_text"] = text[:maximum]
        total_text_length += len(bounded["chunk_text"])
        bounded_results.append(bounded)

    bounded_payload = dict(payload)
    bounded_payload["results"] = bounded_results
    bounded_payload["result_count"] = len(bounded_results)

    return bounded_payload


def search(
    request: SearchRequest,
    *,
    config: ObsidianMCPConfig | None = None,
) -> SearchExecution:
    """Execute one bounded M05 retrieval request."""
    resolved_config = config or load_config()
    vault = resolved_config.require_vault(request.vault_id)

    command = _build_search_command(
        request,
        config=resolved_config,
        vault=vault,
    )

    try:
        completed = subprocess.run(
            command,
            env=_safe_environment(
                resolved_config.runtime.pythonpath
            ),
            capture_output=True,
            text=True,
            timeout=resolved_config.runtime.timeout_seconds,
            check=False,
        )
    except subprocess.TimeoutExpired as exc:
        raise ToolTimeoutError(
            "The Obsidian retrieval request timed out."
        ) from exc
    except OSError as exc:
        raise DependencyError(
            "The Obsidian retrieval runtime is unavailable."
        ) from exc

    if completed.returncode != 0:
        raise ObsidianRetrievalError(
            _parse_error(completed.stderr)
        )

    try:
        payload = json.loads(completed.stdout)
    except json.JSONDecodeError as exc:
        raise ObsidianRetrievalError(
            "The Obsidian retrieval response was not valid JSON."
        ) from exc

    if not isinstance(payload, dict):
        raise ObsidianRetrievalError(
            "The Obsidian retrieval response is invalid."
        )

    return SearchExecution(
        payload=_bound_results(payload)
    )