#!/usr/bin/env python3

"""Read-only semantic retrieval for indexed Obsidian content."""

from __future__ import annotations

import argparse
import json
import sys
from dataclasses import asdict, dataclass
from typing import Any, Iterable, Mapping, Sequence

from obsidian_ingest.embeddings import generate_embeddings
from obsidian_ingest.qdrant import (
    DEFAULT_COLLECTION,
    query_points,
    validate_collection,
)


@dataclass(frozen=True)
class SearchResult:
    score: float
    vault_id: str
    title: str
    relative_path: str
    heading: str | None
    heading_path: tuple[str, ...]
    chunk_text: str
    document_id: str
    chunk_id: str
    tags: tuple[str, ...]


class SearchError(RuntimeError):
    """Raised when an Obsidian retrieval request is invalid."""


def _match_keyword(
    key: str,
    value: Any,
) -> Mapping[str, Any]:
    return {
        "key": key,
        "match": {
            "value": value,
        },
    }


def build_filter(
    *,
    vault_id: str | None = None,
    tag: str | None = None,
    relative_path: str | None = None,
) -> Mapping[str, Any] | None:
    conditions: list[Mapping[str, Any]] = []

    if vault_id:
        conditions.append(
            _match_keyword("vault_id", vault_id)
        )

    if tag:
        conditions.append(
            _match_keyword("tags", tag)
        )

    if relative_path:
        conditions.append(
            _match_keyword("relative_path", relative_path)
        )

    if not conditions:
        return None

    return {
        "must": conditions,
    }


def semantic_search(
    query: str,
    *,
    collection: str = DEFAULT_COLLECTION,
    vault_id: str | None = None,
    tag: str | None = None,
    relative_path: str | None = None,
    limit: int = 5,
    score_threshold: float | None = None,
) -> tuple[SearchResult, ...]:
    normalized_query = query.strip()

    if not normalized_query:
        raise SearchError("Search query cannot be empty")

    validate_collection(collection)

    embedding = generate_embeddings(
        [normalized_query]
    )

    query_filter = build_filter(
        vault_id=vault_id,
        tag=tag,
        relative_path=relative_path,
    )

    points = query_points(
        embedding.vectors[0],
        collection=collection,
        limit=limit,
        score_threshold=score_threshold,
        query_filter=query_filter,
    )

    results: list[SearchResult] = []

    for point in points:
        payload = point.get("payload", {})

        results.append(
            SearchResult(
                score=float(point["score"]),
                vault_id=str(payload.get("vault_id", "")),
                title=str(payload.get("title", "")),
                relative_path=str(
                    payload.get("relative_path", "")
                ),
                heading=payload.get("heading"),
                heading_path=tuple(
                    payload.get("heading_path", [])
                ),
                chunk_text=str(
                    payload.get("chunk_text", "")
                ),
                document_id=str(
                    payload.get("document_id", "")
                ),
                chunk_id=str(
                    payload.get("chunk_id", "")
                ),
                tags=tuple(payload.get("tags", [])),
            )
        )

    return tuple(results)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Search indexed Obsidian content."
    )

    parser.add_argument(
        "query",
        help="Semantic search query.",
    )

    parser.add_argument(
        "--collection",
        default=DEFAULT_COLLECTION,
    )

    parser.add_argument(
        "--vault-id",
    )

    parser.add_argument(
        "--tag",
    )

    parser.add_argument(
        "--relative-path",
    )

    parser.add_argument(
        "--limit",
        type=int,
        default=5,
    )

    parser.add_argument(
        "--score-threshold",
        type=float,
    )

    parser.add_argument(
        "--format",
        choices=("text", "json"),
        default="text",
    )

    return parser


def main(argv: Iterable[str] | None = None) -> int:
    args = build_parser().parse_args(argv)

    try:
        results = semantic_search(
            args.query,
            collection=args.collection,
            vault_id=args.vault_id,
            tag=args.tag,
            relative_path=args.relative_path,
            limit=args.limit,
            score_threshold=args.score_threshold,
        )
    except Exception as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1

    if args.format == "json":
        print(
            json.dumps(
                [asdict(result) for result in results],
                indent=2,
                sort_keys=True,
            )
        )
        return 0

    print(f"query={args.query}")
    print(f"result_count={len(results)}")

    for index, result in enumerate(results, start=1):
        print()
        print(f"rank={index}")
        print(f"score={result.score:.6f}")
        print(f"title={result.title}")
        print(f"path={result.relative_path}")
        print(f"heading={result.heading or ''}")
        print(f"chunk_id={result.chunk_id}")
        print("text:")
        print(result.chunk_text)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())