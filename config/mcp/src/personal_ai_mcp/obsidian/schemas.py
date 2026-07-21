"""Strict schemas for the Obsidian retrieval MCP server."""

from __future__ import annotations

import re
from typing import Annotated
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field, field_validator

from personal_ai_mcp.common.limits import (
    MAX_PATH_LENGTH,
    MAX_TAG_LENGTH,
    QUERY_MAX_LENGTH,
    QUERY_MIN_LENGTH,
    SCORE_THRESHOLD_MAX,
    SCORE_THRESHOLD_MIN,
    SEARCH_DEFAULT_LIMIT,
    SEARCH_MAX_LIMIT,
)


_WINDOWS_ABSOLUTE_PATH = re.compile(r"^[A-Za-z]:[\\/]")


def validate_relative_path(value: str | None) -> str | None:
    """Validate and normalize an exact safe relative path."""
    if value is None:
        return None

    normalized = value.strip().replace("\\", "/")

    if not normalized:
        return None

    if len(normalized) > MAX_PATH_LENGTH:
        raise ValueError("Relative path is too long.")

    lowered = normalized.lower()

    if normalized.startswith(("/", "~")) or lowered.startswith("file:"):
        raise ValueError("Only relative paths are allowed.")

    if _WINDOWS_ABSOLUTE_PATH.match(normalized):
        raise ValueError("Only relative paths are allowed.")

    parts = normalized.split("/")

    if any(part in {"", ".", ".."} for part in parts):
        raise ValueError(
            "Path traversal and empty path segments are prohibited."
        )

    return normalized


class SearchRequest(BaseModel):
    """Validated Obsidian semantic-search request."""

    model_config = ConfigDict(
        extra="forbid",
        str_strip_whitespace=True,
    )

    query: Annotated[
        str,
        Field(
            min_length=QUERY_MIN_LENGTH,
            max_length=QUERY_MAX_LENGTH,
        ),
    ]

    vault_id: Annotated[
        str,
        Field(min_length=1, max_length=100),
    ]

    limit: Annotated[
        int,
        Field(ge=1, le=SEARCH_MAX_LIMIT),
    ] = SEARCH_DEFAULT_LIMIT

    score_threshold: Annotated[
        float,
        Field(
            ge=SCORE_THRESHOLD_MIN,
            le=SCORE_THRESHOLD_MAX,
        ),
    ] | None = None

    tag: Annotated[
        str,
        Field(min_length=1, max_length=MAX_TAG_LENGTH),
    ] | None = None

    relative_path: str | None = None

    @field_validator("relative_path")
    @classmethod
    def check_relative_path(
        cls,
        value: str | None,
    ) -> str | None:
        return validate_relative_path(value)

    @field_validator("tag")
    @classmethod
    def normalize_tag(
        cls,
        value: str | None,
    ) -> str | None:
        if value is None:
            return None

        candidate = value.strip().lstrip("#").lower()

        if not candidate:
            raise ValueError("Tag must not be empty.")

        return candidate


class ChunkRequest(BaseModel):
    """Validated indexed-chunk retrieval request."""

    model_config = ConfigDict(
        extra="forbid",
        str_strip_whitespace=True,
    )

    vault_id: Annotated[
        str,
        Field(min_length=1, max_length=100),
    ]

    chunk_id: UUID


class VaultRequest(BaseModel):
    """Validated request scope for retrieval status."""

    model_config = ConfigDict(
        extra="forbid",
        str_strip_whitespace=True,
    )

    vault_id: Annotated[
        str,
        Field(min_length=1, max_length=100),
    ]