#!/usr/bin/env python3

"""Constrained read-only retrieval boundary for OpenClaw."""

from __future__ import annotations

import argparse
import json
import sys
from dataclasses import asdict, dataclass
from typing import Iterable

from obsidian_ingest.qdrant import DEFAULT_COLLECTION
from obsidian_ingest.search import semantic_search


DEFAULT_LIMIT = 5
MAXIMUM_LIMIT = 8
MAXIMUM_QUERY_LENGTH = 500
DEFAULT_SCORE_THRESHOLD = 0.35


class RetrievalBoundaryError(RuntimeError):
    """Raised when a retrieval request violates boundary rules."""


@dataclass(frozen=True)
class RetrievalItem:
    rank: int
    score: float
    title: str
    relative_path: str
    heading: str | None
    chunk_text: str
    tags: tuple[str, ...]
    document_id: str
    chunk_id: str


@dataclass(frozen=True)
class RetrievalResponse:
    schema_version: int
    query: str
    vault_id: str
    collection: str
    result_count: int
    results: tuple[RetrievalItem, ...]


def validate_request(
    query: str,
    *,
    vault_id: str,
    limit: int,
) -> str:
    normalized_query = query.strip()

    if not normalized_query:
        raise RetrievalBoundaryError(
            "Query cannot be empty"
        )

    if len(normalized_query) > MAXIMUM_QUERY_LENGTH:
        raise RetrievalBoundaryError(
            "Query exceeds maximum length: "
            f"maximum={MAXIMUM_QUERY_LENGTH}"
        )

    if not vault_id.strip():
        raise RetrievalBoundaryError(
            "Vault ID cannot be empty"
        )

    if limit <= 0:
        raise RetrievalBoundaryError(
            "Limit must be positive"
        )

    if limit > MAXIMUM_LIMIT:
        raise RetrievalBoundaryError(
            "Limit exceeds boundary maximum: "
            f"requested={limit}, maximum={MAXIMUM_LIMIT}"
        )

    return normalized_query


def retrieve(
    query: str,
    *,
    vault_id: str,
    collection: str = DEFAULT_COLLECTION,
    limit: int = DEFAULT_LIMIT,
    score_threshold: float = DEFAULT_SCORE_THRESHOLD,
    tag: str | None = None,
    relative_path: str | None = None,
) -> RetrievalResponse:
    normalized_query = validate_request(
        query,
        vault_id=vault_id,
        limit=limit,
    )

    search_results = semantic_search(
        normalized_query,
        collection=collection,
        vault_id=vault_id,
        tag=tag,
        relative_path=relative_path,
        limit=limit,
        score_threshold=score_threshold,
    )

    items = tuple(
        RetrievalItem(
            rank=index,
            score=result.score,
            title=result.title,
            relative_path=result.relative_path,
            heading=result.heading,
            chunk_text=result.chunk_text,
            tags=result.tags,
            document_id=result.document_id,
            chunk_id=result.chunk_id,
        )
        for index, result in enumerate(
            search_results,
            start=1,
        )
    )

    return RetrievalResponse(
        schema_version=1,
        query=normalized_query,
        vault_id=vault_id,
        collection=collection,
        result_count=len(items),
        results=items,
    )


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Execute a constrained read-only Obsidian retrieval request."
        )
    )

    parser.add_argument(
        "query",
        help="Semantic retrieval query.",
    )

    parser.add_argument(
        "--vault-id",
        required=True,
        help="Approved configured vault identifier.",
    )

    parser.add_argument(
        "--collection",
        default=DEFAULT_COLLECTION,
    )

    parser.add_argument(
        "--limit",
        type=int,
        default=DEFAULT_LIMIT,
    )

    parser.add_argument(
        "--score-threshold",
        type=float,
        default=DEFAULT_SCORE_THRESHOLD,
    )

    parser.add_argument(
        "--tag",
    )

    parser.add_argument(
        "--relative-path",
    )

    return parser


def main(argv: Iterable[str] | None = None) -> int:
    args = build_parser().parse_args(argv)

    try:
        response = retrieve(
            args.query,
            vault_id=args.vault_id,
            collection=args.collection,
            limit=args.limit,
            score_threshold=args.score_threshold,
            tag=args.tag,
            relative_path=args.relative_path,
        )
    except Exception as exc:
        print(
            json.dumps(
                {
                    "schema_version": 1,
                    "error": {
                        "type": type(exc).__name__,
                        "message": str(exc),
                    },
                },
                sort_keys=True,
            ),
            file=sys.stderr,
        )
        return 1

    print(
        json.dumps(
            asdict(response),
            indent=2,
            sort_keys=True,
        )
    )

    return 0


if __name__ == "__main__":
    raise SystemExit(main())