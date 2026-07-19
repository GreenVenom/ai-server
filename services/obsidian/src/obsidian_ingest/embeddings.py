#!/usr/bin/env python3

"""Local Ollama embedding client for Obsidian indexing."""

from __future__ import annotations

import json
import urllib.error
import urllib.request
from dataclasses import dataclass
from typing import Sequence


DEFAULT_OLLAMA_URL = "http://127.0.0.1:11434"
DEFAULT_MODEL = "nomic-embed-text:latest"
EXPECTED_DIMENSION = 768


class EmbeddingError(RuntimeError):
    """Raised when embedding generation fails."""


@dataclass(frozen=True)
class EmbeddingResult:
    model: str
    vectors: tuple[tuple[float, ...], ...]
    dimension: int


def generate_embeddings(
    texts: Sequence[str],
    *,
    model: str = DEFAULT_MODEL,
    base_url: str = DEFAULT_OLLAMA_URL,
    timeout_seconds: int = 120,
) -> EmbeddingResult:
    if not texts:
        raise EmbeddingError("At least one input text is required")

    payload = json.dumps(
        {
            "model": model,
            "input": list(texts),
        }
    ).encode("utf-8")

    request = urllib.request.Request(
        f"{base_url.rstrip('/')}/api/embed",
        data=payload,
        method="POST",
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
        body = exc.read().decode("utf-8", errors="replace")
        raise EmbeddingError(
            f"Ollama embedding request failed: HTTP {exc.code}: {body}"
        ) from exc
    except urllib.error.URLError as exc:
        raise EmbeddingError(
            f"Unable to reach Ollama embedding endpoint: {exc}"
        ) from exc
    except TimeoutError as exc:
        raise EmbeddingError(
            "Ollama embedding request timed out"
        ) from exc

    raw_vectors = data.get("embeddings")

    if not isinstance(raw_vectors, list) or not raw_vectors:
        raise EmbeddingError("Ollama returned no embeddings")

    if len(raw_vectors) != len(texts):
        raise EmbeddingError(
            "Embedding count does not match input count"
        )

    vectors: list[tuple[float, ...]] = []

    for index, raw_vector in enumerate(raw_vectors):
        if not isinstance(raw_vector, list):
            raise EmbeddingError(
                f"Embedding {index} is not a vector"
            )

        try:
            vector = tuple(float(value) for value in raw_vector)
        except (TypeError, ValueError) as exc:
            raise EmbeddingError(
                f"Embedding {index} contains a non-numeric value"
            ) from exc

        if not vector:
            raise EmbeddingError(
                f"Embedding {index} is empty"
            )

        vectors.append(vector)

    dimensions = {len(vector) for vector in vectors}

    if len(dimensions) != 1:
        raise EmbeddingError(
            f"Inconsistent embedding dimensions: {sorted(dimensions)}"
        )

    dimension = dimensions.pop()

    if dimension != EXPECTED_DIMENSION:
        raise EmbeddingError(
            "Unexpected embedding dimension: "
            f"expected={EXPECTED_DIMENSION}, actual={dimension}"
        )

    return EmbeddingResult(
        model=str(data.get("model", model)),
        vectors=tuple(vectors),
        dimension=dimension,
    )