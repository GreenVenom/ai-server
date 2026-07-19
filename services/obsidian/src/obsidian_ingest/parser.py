#!/usr/bin/env python3

"""Obsidian Markdown parser and index-decision logic."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Any, Iterable, Mapping, Sequence

import yaml


FRONTMATTER_DELIMITER = "---"

HEADING_PATTERN = re.compile(
    r"^(?P<marks>#{1,6})[ \t]+(?P<title>.+?)[ \t]*#*[ \t]*$"
)

WIKILINK_PATTERN = re.compile(
    r"(?<!!)\[\["
    r"(?P<target>[^\]|#]+)"
    r"(?:#(?P<heading>[^\]|]+))?"
    r"(?:\|(?P<label>[^\]]+))?"
    r"\]\]"
)

EMBED_PATTERN = re.compile(
    r"!\[\["
    r"(?P<target>[^\]|#]+)"
    r"(?:#(?P<heading>[^\]|]+))?"
    r"(?:\|(?P<label>[^\]]+))?"
    r"\]\]"
)

MARKDOWN_LINK_PATTERN = re.compile(
    r"(?<!!)\[(?P<label>[^\]]+)\]\((?P<target>[^)]+)\)"
)

INLINE_TAG_PATTERN = re.compile(
    r"(?<![\w/])#(?P<tag>[A-Za-z0-9_/-]+)"
)


@dataclass(frozen=True)
class Heading:
    level: int
    title: str
    line_number: int
    path: tuple[str, ...]


@dataclass(frozen=True)
class WikiLink:
    target: str
    heading: str | None
    label: str | None
    embedded: bool


@dataclass(frozen=True)
class MarkdownLink:
    label: str
    target: str


@dataclass(frozen=True)
class ParseIssue:
    severity: str
    code: str
    message: str
    line_number: int | None = None


@dataclass(frozen=True)
class ParsedDocument:
    relative_path: str
    title: str
    source_text: str
    body_text: str
    source_hash: str
    frontmatter: Mapping[str, Any]
    aliases: tuple[str, ...]
    tags: tuple[str, ...]
    headings: tuple[Heading, ...]
    wikilinks: tuple[WikiLink, ...]
    markdown_links: tuple[MarkdownLink, ...]
    should_index: bool
    index_reason: str
    issues: tuple[ParseIssue, ...]


class DocumentParseError(RuntimeError):
    """Raised when a Markdown document cannot be read or parsed safely."""


def _sha256_text(value: str) -> str:
    return hashlib.sha256(value.encode("utf-8")).hexdigest()


def _normalize_newlines(value: str) -> str:
    return value.replace("\r\n", "\n").replace("\r", "\n")


def _normalize_string_sequence(value: Any) -> tuple[str, ...]:
    if value is None:
        return ()

    if isinstance(value, str):
        candidates: Sequence[Any] = (value,)
    elif isinstance(value, Sequence) and not isinstance(
        value,
        (bytes, bytearray),
    ):
        candidates = value
    else:
        candidates = (value,)

    normalized: list[str] = []

    for candidate in candidates:
        text = str(candidate).strip()

        if not text:
            continue

        if text.startswith("#"):
            text = text[1:]

        if text and text not in normalized:
            normalized.append(text)

    return tuple(normalized)


def _frontmatter_boolean(
    frontmatter: Mapping[str, Any],
    key: str,
) -> bool | None:
    if key not in frontmatter:
        return None

    value = frontmatter[key]

    if isinstance(value, bool):
        return value

    if isinstance(value, int):
        return value != 0

    if isinstance(value, str):
        normalized = value.strip().lower()

        if normalized in {"true", "yes", "on", "1"}:
            return True

        if normalized in {"false", "no", "off", "0"}:
            return False

    return None


def _split_frontmatter(
    source_text: str,
) -> tuple[Mapping[str, Any], str, tuple[ParseIssue, ...]]:
    lines = source_text.splitlines(keepends=True)

    if not lines:
        return {}, "", ()

    if lines[0].strip() != FRONTMATTER_DELIMITER:
        return {}, source_text, ()

    closing_index: int | None = None

    for index in range(1, len(lines)):
        if lines[index].strip() == FRONTMATTER_DELIMITER:
            closing_index = index
            break

    if closing_index is None:
        issue = ParseIssue(
            severity="error",
            code="frontmatter_unclosed",
            message="Opening YAML frontmatter delimiter has no closing delimiter.",
            line_number=1,
        )

        return {}, source_text, (issue,)

    raw_frontmatter = "".join(lines[1:closing_index])
    body_text = "".join(lines[closing_index + 1:])

    try:
        loaded = yaml.safe_load(raw_frontmatter)
    except yaml.YAMLError as exc:
        mark = getattr(exc, "problem_mark", None)
        line_number = None

        if mark is not None:
            line_number = mark.line + 2

        issue = ParseIssue(
            severity="error",
            code="frontmatter_invalid_yaml",
            message=str(exc).strip(),
            line_number=line_number,
        )

        return {}, body_text, (issue,)

    if loaded is None:
        return {}, body_text, ()

    if not isinstance(loaded, Mapping):
        issue = ParseIssue(
            severity="error",
            code="frontmatter_not_mapping",
            message="YAML frontmatter must contain a mapping/object.",
            line_number=2,
        )

        return {}, body_text, (issue,)

    return dict(loaded), body_text, ()


def _extract_headings(body_text: str) -> tuple[Heading, ...]:
    headings: list[Heading] = []
    hierarchy: list[str] = []
    in_fenced_code_block = False
    active_fence: str | None = None

    for line_number, line in enumerate(body_text.splitlines(), start=1):
        stripped = line.lstrip()

        if stripped.startswith("```") or stripped.startswith("~~~"):
            fence = stripped[:3]

            if not in_fenced_code_block:
                in_fenced_code_block = True
                active_fence = fence
            elif fence == active_fence:
                in_fenced_code_block = False
                active_fence = None

            continue

        if in_fenced_code_block:
            continue

        match = HEADING_PATTERN.match(line)

        if match is None:
            continue

        level = len(match.group("marks"))
        title = match.group("title").strip()

        hierarchy = hierarchy[: level - 1]
        hierarchy.append(title)

        headings.append(
            Heading(
                level=level,
                title=title,
                line_number=line_number,
                path=tuple(hierarchy),
            )
        )

    return tuple(headings)


def _extract_wikilinks(body_text: str) -> tuple[WikiLink, ...]:
    matches: list[WikiLink] = []

    for pattern, embedded in (
        (EMBED_PATTERN, True),
        (WIKILINK_PATTERN, False),
    ):
        for match in pattern.finditer(body_text):
            item = WikiLink(
                target=match.group("target").strip(),
                heading=(
                    match.group("heading").strip()
                    if match.group("heading")
                    else None
                ),
                label=(
                    match.group("label").strip()
                    if match.group("label")
                    else None
                ),
                embedded=embedded,
            )

            if item not in matches:
                matches.append(item)

    return tuple(matches)


def _extract_markdown_links(
    body_text: str,
) -> tuple[MarkdownLink, ...]:
    matches: list[MarkdownLink] = []

    for match in MARKDOWN_LINK_PATTERN.finditer(body_text):
        item = MarkdownLink(
            label=match.group("label").strip(),
            target=match.group("target").strip(),
        )

        if item not in matches:
            matches.append(item)

    return tuple(matches)


def _extract_inline_tags(body_text: str) -> tuple[str, ...]:
    tags: list[str] = []
    in_fenced_code_block = False
    active_fence: str | None = None

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

            continue

        if in_fenced_code_block:
            continue

        for match in INLINE_TAG_PATTERN.finditer(line):
            tag = match.group("tag").strip("/")

            if tag and tag not in tags:
                tags.append(tag)

    return tuple(tags)


def _select_title(
    relative_path: str,
    frontmatter: Mapping[str, Any],
    headings: Sequence[Heading],
) -> str:
    frontmatter_title = frontmatter.get("title")

    if frontmatter_title is not None:
        normalized = str(frontmatter_title).strip()

        if normalized:
            return normalized

    for heading in headings:
        if heading.level == 1:
            return heading.title

    return Path(relative_path).stem


def _index_decision(
    frontmatter: Mapping[str, Any],
    issues: Sequence[ParseIssue],
    body_text: str,
) -> tuple[bool, str]:
    if any(issue.severity == "error" for issue in issues):
        return False, "parse_error"

    excluded = _frontmatter_boolean(frontmatter, "ai_exclude")

    if excluded is True:
        return False, "frontmatter_excluded"

    included = _frontmatter_boolean(frontmatter, "ai_index")

    if included is False:
        return False, "frontmatter_disabled"

    if not body_text.strip():
        return False, "empty_document"

    return True, "included"


def parse_document(
    path: Path,
    *,
    root: Path,
) -> ParsedDocument:
    root = root.expanduser().resolve()
    path = path.expanduser().resolve()

    try:
        relative_path = path.relative_to(root).as_posix()
    except ValueError as exc:
        raise DocumentParseError(
            f"Document is outside the configured root: {path}"
        ) from exc

    if not path.exists():
        raise DocumentParseError(f"Document does not exist: {path}")

    if not path.is_file():
        raise DocumentParseError(f"Document is not a file: {path}")

    try:
        raw_bytes = path.read_bytes()
    except OSError as exc:
        raise DocumentParseError(
            f"Unable to read document: {path}: {exc}"
        ) from exc

    try:
        source_text = raw_bytes.decode("utf-8")
    except UnicodeDecodeError as exc:
        raise DocumentParseError(
            f"Document is not valid UTF-8: {path}: {exc}"
        ) from exc

    source_text = _normalize_newlines(source_text)

    frontmatter, body_text, frontmatter_issues = _split_frontmatter(
        source_text
    )

    headings = _extract_headings(body_text)
    aliases = _normalize_string_sequence(frontmatter.get("aliases"))

    frontmatter_tags = _normalize_string_sequence(
        frontmatter.get("tags")
    )

    inline_tags = _extract_inline_tags(body_text)

    tags = tuple(
        dict.fromkeys((*frontmatter_tags, *inline_tags))
    )

    wikilinks = _extract_wikilinks(body_text)
    markdown_links = _extract_markdown_links(body_text)

    should_index, index_reason = _index_decision(
        frontmatter,
        frontmatter_issues,
        body_text,
    )

    title = _select_title(
        relative_path,
        frontmatter,
        headings,
    )

    return ParsedDocument(
        relative_path=relative_path,
        title=title,
        source_text=source_text,
        body_text=body_text,
        source_hash=_sha256_text(source_text),
        frontmatter=frontmatter,
        aliases=aliases,
        tags=tags,
        headings=headings,
        wikilinks=wikilinks,
        markdown_links=markdown_links,
        should_index=should_index,
        index_reason=index_reason,
        issues=frontmatter_issues,
    )


def _serialize(document: ParsedDocument) -> dict[str, Any]:
    return asdict(document)


def _print_text(document: ParsedDocument) -> None:
    print(f"relative_path={document.relative_path}")
    print(f"title={document.title}")
    print(f"source_hash={document.source_hash}")
    print(f"should_index={str(document.should_index).lower()}")
    print(f"index_reason={document.index_reason}")
    print(f"aliases={list(document.aliases)}")
    print(f"tags={list(document.tags)}")
    print(f"heading_count={len(document.headings)}")
    print(f"wikilink_count={len(document.wikilinks)}")
    print(f"markdown_link_count={len(document.markdown_links)}")
    print(f"issue_count={len(document.issues)}")

    print("\nheadings:")
    for heading in document.headings:
        print(
            f"  level={heading.level}"
            f" line={heading.line_number}"
            f" path={' > '.join(heading.path)}"
        )

    print("\nwikilinks:")
    for link in document.wikilinks:
        print(
            f"  target={link.target}"
            f" heading={link.heading or ''}"
            f" label={link.label or ''}"
            f" embedded={str(link.embedded).lower()}"
        )

    print("\nissues:")
    for issue in document.issues:
        print(
            f"  severity={issue.severity}"
            f" code={issue.code}"
            f" line={issue.line_number or ''}"
            f" message={issue.message}"
        )


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Parse one Obsidian Markdown document."
    )

    parser.add_argument(
        "path",
        type=Path,
        help="Markdown file to parse.",
    )

    parser.add_argument(
        "--root",
        required=True,
        type=Path,
        help="Approved vault or fixture root.",
    )

    parser.add_argument(
        "--format",
        choices=("text", "json"),
        default="text",
        help="Output format.",
    )

    return parser


def main(argv: Iterable[str] | None = None) -> int:
    args = build_parser().parse_args(argv)

    try:
        document = parse_document(
            args.path,
            root=args.root,
        )
    except DocumentParseError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1

    if args.format == "json":
        print(
            json.dumps(
                _serialize(document),
                indent=2,
                sort_keys=True,
            )
        )
    else:
        _print_text(document)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())


def document_metadata_hash(
    document: ParsedDocument,
) -> str:
    """Hash normalized metadata that affects indexing or retrieval."""

    metadata = {
        "title": document.title,
        "aliases": list(document.aliases),
        "tags": list(document.tags),
        "wikilinks": [
            {
                "target": link.target,
                "heading": link.heading,
                "label": link.label,
                "embedded": link.embedded,
            }
            for link in document.wikilinks
        ],
        "markdown_links": [
            {
                "label": link.label,
                "target": link.target,
            }
            for link in document.markdown_links
        ],
        "visibility": str(
            document.frontmatter.get("visibility", "private")
        ),
        "ai_index": document.frontmatter.get("ai_index"),
        "ai_exclude": document.frontmatter.get("ai_exclude"),
    }

    normalized = json.dumps(
        metadata,
        sort_keys=True,
        separators=(",", ":"),
        ensure_ascii=False,
    )

    return _sha256_text(normalized)