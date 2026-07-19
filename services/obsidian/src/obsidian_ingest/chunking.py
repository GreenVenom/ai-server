#!/usr/bin/env python3

"""Heading-aware deterministic chunking for Obsidian Markdown."""

from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Iterable, Sequence

from obsidian_ingest.identity import (
    chunk_id,
    document_id,
    sha256_text,
)
from obsidian_ingest.parser import (
    DocumentParseError,
    ParsedDocument,
    parse_document,
)


CHUNKING_PROFILE = "heading-aware-v1"

HEADING_PATTERN = re.compile(
    r"^(?P<marks>#{1,6})[ \t]+(?P<title>.+?)[ \t]*#*[ \t]*$"
)

SENTENCE_BOUNDARY_PATTERN = re.compile(
    r"(?<=[.!?])\s+"
)


@dataclass(frozen=True)
class ChunkingConfig:
    target_tokens: int = 700
    maximum_tokens: int = 1200
    overlap_tokens: int = 100
    minimum_tokens: int = 40


@dataclass(frozen=True)
class Section:
    heading: str | None
    heading_path: tuple[str, ...]
    heading_level: int | None
    body: str
    section_index: int


@dataclass(frozen=True)
class DocumentChunk:
    document_id: str
    chunk_id: str
    chunk_key: str
    chunk_index: int
    chunk_count: int
    heading: str | None
    heading_path: tuple[str, ...]
    heading_level: int | None
    chunk_text: str
    embedding_text: str
    token_count: int
    content_hash: str
    chunking_profile: str


class ChunkingError(RuntimeError):
    """Raised when chunking configuration or input is invalid."""


def approximate_token_count(value: str) -> int:
    """Return a deterministic approximate token count."""

    return len(re.findall(r"\S+", value))


def normalize_chunk_text(value: str) -> str:
    """Normalize whitespace while retaining paragraph boundaries."""

    normalized_lines = [
        line.rstrip()
        for line in value.replace("\r\n", "\n").replace("\r", "\n").split("\n")
    ]

    normalized = "\n".join(normalized_lines).strip()

    while "\n\n\n" in normalized:
        normalized = normalized.replace("\n\n\n", "\n\n")

    return normalized


def _validate_config(config: ChunkingConfig) -> None:
    if config.target_tokens <= 0:
        raise ChunkingError("target_tokens must be positive")

    if config.maximum_tokens < config.target_tokens:
        raise ChunkingError(
            "maximum_tokens must be greater than or equal to target_tokens"
        )

    if config.overlap_tokens < 0:
        raise ChunkingError("overlap_tokens cannot be negative")

    if config.overlap_tokens >= config.maximum_tokens:
        raise ChunkingError(
            "overlap_tokens must be smaller than maximum_tokens"
        )

    if config.minimum_tokens < 0:
        raise ChunkingError("minimum_tokens cannot be negative")


def _split_into_sections(body_text: str) -> tuple[Section, ...]:
    sections: list[Section] = []
    hierarchy: list[str] = []

    current_heading: str | None = None
    current_heading_path: tuple[str, ...] = ()
    current_heading_level: int | None = None
    current_lines: list[str] = []
    section_index = 0

    in_fenced_code_block = False
    active_fence: str | None = None

    def flush() -> None:
        nonlocal section_index
        nonlocal current_lines

        body = normalize_chunk_text("\n".join(current_lines))

        if body:
            sections.append(
                Section(
                    heading=current_heading,
                    heading_path=current_heading_path,
                    heading_level=current_heading_level,
                    body=body,
                    section_index=section_index,
                )
            )
            section_index += 1

        current_lines = []

    for line in body_text.splitlines():
        stripped = line.lstrip()

        if stripped.startswith("```") or stripped.startswith("~~~"):
            fence = stripped[:3]

            if not in_fenced_code_block:
                in_fenced_code_block = True
                active_fence = fence
            elif fence == active_fence:
                in_fenced_code_block = False
                active_fence = None

            current_lines.append(line)
            continue

        if not in_fenced_code_block:
            match = HEADING_PATTERN.match(line)

            if match is not None:
                flush()

                level = len(match.group("marks"))
                title = match.group("title").strip()

                hierarchy = hierarchy[: level - 1]
                hierarchy.append(title)

                current_heading = title
                current_heading_path = tuple(hierarchy)
                current_heading_level = level
                continue

        current_lines.append(line)

    flush()

    return tuple(sections)


def _split_paragraphs(value: str) -> list[str]:
    return [
        paragraph.strip()
        for paragraph in re.split(r"\n\s*\n", value)
        if paragraph.strip()
    ]


def _split_oversized_paragraph(
    paragraph: str,
    maximum_tokens: int,
) -> list[str]:
    if approximate_token_count(paragraph) <= maximum_tokens:
        return [paragraph]

    sentences = [
        sentence.strip()
        for sentence in SENTENCE_BOUNDARY_PATTERN.split(paragraph)
        if sentence.strip()
    ]

    if len(sentences) <= 1:
        words = paragraph.split()

        return [
            " ".join(words[index:index + maximum_tokens])
            for index in range(0, len(words), maximum_tokens)
        ]

    pieces: list[str] = []
    current: list[str] = []

    for sentence in sentences:
        candidate = " ".join((*current, sentence))

        if (
            current
            and approximate_token_count(candidate) > maximum_tokens
        ):
            pieces.append(" ".join(current))
            current = [sentence]
        else:
            current.append(sentence)

    if current:
        pieces.append(" ".join(current))

    final_pieces: list[str] = []

    for piece in pieces:
        if approximate_token_count(piece) <= maximum_tokens:
            final_pieces.append(piece)
            continue

        words = piece.split()

        final_pieces.extend(
            " ".join(words[index:index + maximum_tokens])
            for index in range(0, len(words), maximum_tokens)
        )

    return final_pieces


def _take_overlap(
    value: str,
    overlap_tokens: int,
) -> str:
    if overlap_tokens <= 0:
        return ""

    words = value.split()

    return " ".join(words[-overlap_tokens:])


def _split_section(
    section: Section,
    config: ChunkingConfig,
) -> list[str]:
    paragraphs = _split_paragraphs(section.body)

    expanded_paragraphs: list[str] = []

    for paragraph in paragraphs:
        expanded_paragraphs.extend(
            _split_oversized_paragraph(
                paragraph,
                config.maximum_tokens,
            )
        )

    chunks: list[str] = []
    current: list[str] = []

    for paragraph in expanded_paragraphs:
        candidate = "\n\n".join((*current, paragraph))

        if (
            current
            and approximate_token_count(candidate) > config.target_tokens
        ):
            completed = normalize_chunk_text("\n\n".join(current))
            chunks.append(completed)

            overlap = _take_overlap(
                completed,
                config.overlap_tokens,
            )

            current = [overlap, paragraph] if overlap else [paragraph]
        else:
            current.append(paragraph)

        current_value = normalize_chunk_text("\n\n".join(current))

        if approximate_token_count(current_value) > config.maximum_tokens:
            completed = normalize_chunk_text(
                "\n\n".join(current[:-1])
            )

            if completed:
                chunks.append(completed)

                overlap = _take_overlap(
                    completed,
                    config.overlap_tokens,
                )

                current = [overlap, paragraph] if overlap else [paragraph]
            else:
                chunks.extend(
                    _split_oversized_paragraph(
                        paragraph,
                        config.maximum_tokens,
                    )
                )
                current = []

    if current:
        chunks.append(
            normalize_chunk_text("\n\n".join(current))
        )

    return [chunk for chunk in chunks if chunk]


def _merge_short_chunks(
    values: Sequence[str],
    config: ChunkingConfig,
) -> list[str]:
    if not values:
        return []

    merged: list[str] = []

    for value in values:
        token_count = approximate_token_count(value)

        if (
            merged
            and token_count < config.minimum_tokens
            and approximate_token_count(
                f"{merged[-1]}\n\n{value}"
            ) <= config.maximum_tokens
        ):
            merged[-1] = normalize_chunk_text(
                f"{merged[-1]}\n\n{value}"
            )
        else:
            merged.append(value)

    return merged


def _embedding_text(
    document: ParsedDocument,
    section: Section,
    chunk_text: str,
) -> str:
    context: list[str] = [f"Title: {document.title}"]

    if section.heading_path:
        context.append(
            f"Section: {' > '.join(section.heading_path)}"
        )

    context.append(chunk_text)

    return "\n\n".join(context)


def chunk_document(
    document: ParsedDocument,
    *,
    vault_id: str,
    config: ChunkingConfig = ChunkingConfig(),
) -> tuple[DocumentChunk, ...]:
    _validate_config(config)

    if not document.should_index:
        return ()

    sections = _split_into_sections(document.body_text)
    provisional: list[tuple[Section, int, str]] = []

    for section in sections:
        section_chunks = _merge_short_chunks(
            _split_section(section, config),
            config,
        )

        for ordinal, text in enumerate(section_chunks):
            provisional.append(
                (
                    section,
                    ordinal,
                    text,
                )
            )

    total = len(provisional)
    doc_id = document_id(
        vault_id,
        document.relative_path,
    )

    chunks: list[DocumentChunk] = []

    for global_index, item in enumerate(provisional):
        section, section_ordinal, text = item

        heading_identity = (
            " > ".join(section.heading_path)
            if section.heading_path
            else "__document__"
        )

        chunk_key = "|".join(
            (
                CHUNKING_PROFILE,
                heading_identity,
                str(section_ordinal),
            )
        )

        embedding_text = _embedding_text(
            document,
            section,
            text,
        )

        chunks.append(
            DocumentChunk(
                document_id=doc_id,
                chunk_id=chunk_id(
                    vault_id,
                    document.relative_path,
                    chunk_key,
                ),
                chunk_key=chunk_key,
                chunk_index=global_index,
                chunk_count=total,
                heading=section.heading,
                heading_path=section.heading_path,
                heading_level=section.heading_level,
                chunk_text=text,
                embedding_text=embedding_text,
                token_count=approximate_token_count(text),
                content_hash=sha256_text(text),
                chunking_profile=CHUNKING_PROFILE,
            )
        )

    return tuple(chunks)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Parse and chunk one Obsidian Markdown document."
    )

    parser.add_argument(
        "path",
        type=Path,
        help="Markdown document to chunk.",
    )

    parser.add_argument(
        "--root",
        required=True,
        type=Path,
        help="Approved fixture or vault root.",
    )

    parser.add_argument(
        "--vault-id",
        required=True,
        help="Stable configured vault identifier.",
    )

    parser.add_argument(
        "--target-tokens",
        type=int,
        default=700,
    )

    parser.add_argument(
        "--maximum-tokens",
        type=int,
        default=1200,
    )

    parser.add_argument(
        "--overlap-tokens",
        type=int,
        default=100,
    )

    parser.add_argument(
        "--minimum-tokens",
        type=int,
        default=40,
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
        document = parse_document(
            args.path,
            root=args.root,
        )

        chunks = chunk_document(
            document,
            vault_id=args.vault_id,
            config=ChunkingConfig(
                target_tokens=args.target_tokens,
                maximum_tokens=args.maximum_tokens,
                overlap_tokens=args.overlap_tokens,
                minimum_tokens=args.minimum_tokens,
            ),
        )
    except (DocumentParseError, ChunkingError) as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1

    if args.format == "json":
        print(
            json.dumps(
                [asdict(chunk) for chunk in chunks],
                indent=2,
                sort_keys=True,
            )
        )
        return 0

    print(f"relative_path={document.relative_path}")
    print(f"document_id={document_id(args.vault_id, document.relative_path)}")
    print(f"should_index={str(document.should_index).lower()}")
    print(f"chunk_count={len(chunks)}")

    for chunk in chunks:
        print()
        print(f"chunk_index={chunk.chunk_index}")
        print(f"chunk_id={chunk.chunk_id}")
        print(f"chunk_key={chunk.chunk_key}")
        print(f"heading={chunk.heading or ''}")
        print(f"heading_path={' > '.join(chunk.heading_path)}")
        print(f"token_count={chunk.token_count}")
        print(f"content_hash={chunk.content_hash}")
        print("chunk_text:")
        print(chunk.chunk_text)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())