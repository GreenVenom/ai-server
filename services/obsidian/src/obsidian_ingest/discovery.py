#!/usr/bin/env python3

"""Deterministic Markdown discovery for Obsidian vault mirrors."""

from __future__ import annotations

import argparse
import fnmatch
import json
import os
import sys
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Iterable, Sequence


DEFAULT_EXCLUDED_DIRECTORIES = (
    ".obsidian",
    ".trash",
    "templates",
)

DEFAULT_EXCLUDED_PATTERNS = (
    "*.excalidraw.md",
)


@dataclass(frozen=True)
class DiscoveredFile:
    relative_path: str
    absolute_path: str
    size_bytes: int
    modified_ns: int


@dataclass(frozen=True)
class SkippedPath:
    relative_path: str
    reason: str


@dataclass(frozen=True)
class DiscoveryResult:
    root: str
    discovered: tuple[DiscoveredFile, ...]
    skipped: tuple[SkippedPath, ...]


class DiscoveryError(RuntimeError):
    """Raised when a vault root cannot be discovered safely."""


def _normalized_relative_path(root: Path, path: Path) -> str:
    return path.relative_to(root).as_posix()


def _matches_pattern(relative_path: str, patterns: Sequence[str]) -> bool:
    name = Path(relative_path).name

    return any(
        fnmatch.fnmatch(relative_path, pattern)
        or fnmatch.fnmatch(name, pattern)
        for pattern in patterns
    )


def discover_markdown(
    root: Path,
    *,
    excluded_directories: Sequence[str] = DEFAULT_EXCLUDED_DIRECTORIES,
    excluded_patterns: Sequence[str] = DEFAULT_EXCLUDED_PATTERNS,
    follow_symlinks: bool = False,
) -> DiscoveryResult:
    """Discover Markdown files under root in deterministic path order."""

    root = root.expanduser().resolve()

    if not root.exists():
        raise DiscoveryError(f"Vault root does not exist: {root}")

    if not root.is_dir():
        raise DiscoveryError(f"Vault root is not a directory: {root}")

    excluded_directory_set = set(excluded_directories)
    discovered: list[DiscoveredFile] = []
    skipped: list[SkippedPath] = []

    for current_root, directory_names, file_names in os.walk(
        root,
        followlinks=follow_symlinks,
    ):
        current_path = Path(current_root)

        retained_directories: list[str] = []

        for directory_name in sorted(directory_names):
            candidate = current_path / directory_name
            relative = _normalized_relative_path(root, candidate)

            if directory_name in excluded_directory_set:
                skipped.append(
                    SkippedPath(
                        relative_path=relative,
                        reason="excluded_directory",
                    )
                )
                continue

            if candidate.is_symlink() and not follow_symlinks:
                skipped.append(
                    SkippedPath(
                        relative_path=relative,
                        reason="symlink_directory",
                    )
                )
                continue

            retained_directories.append(directory_name)

        directory_names[:] = retained_directories

        for file_name in sorted(file_names):
            candidate = current_path / file_name
            relative = _normalized_relative_path(root, candidate)

            if candidate.is_symlink() and not follow_symlinks:
                skipped.append(
                    SkippedPath(
                        relative_path=relative,
                        reason="symlink_file",
                    )
                )
                continue

            if candidate.suffix.lower() != ".md":
                skipped.append(
                    SkippedPath(
                        relative_path=relative,
                        reason="unsupported_extension",
                    )
                )
                continue

            if _matches_pattern(relative, excluded_patterns):
                skipped.append(
                    SkippedPath(
                        relative_path=relative,
                        reason="excluded_pattern",
                    )
                )
                continue

            stat_result = candidate.stat()

            discovered.append(
                DiscoveredFile(
                    relative_path=relative,
                    absolute_path=str(candidate),
                    size_bytes=stat_result.st_size,
                    modified_ns=stat_result.st_mtime_ns,
                )
            )

    discovered.sort(key=lambda item: item.relative_path)
    skipped.sort(key=lambda item: (item.relative_path, item.reason))

    return DiscoveryResult(
        root=str(root),
        discovered=tuple(discovered),
        skipped=tuple(skipped),
    )


def _print_text(result: DiscoveryResult) -> None:
    print(f"root={result.root}")
    print(f"discovered_count={len(result.discovered)}")
    print(f"skipped_count={len(result.skipped)}")

    print("\ndiscovered:")
    for item in result.discovered:
        print(
            f"  {item.relative_path}"
            f" size={item.size_bytes}"
            f" modified_ns={item.modified_ns}"
        )

    print("\nskipped:")
    for item in result.skipped:
        print(f"  {item.relative_path} reason={item.reason}")


def _print_json(result: DiscoveryResult) -> None:
    payload = {
        "root": result.root,
        "discovered_count": len(result.discovered),
        "skipped_count": len(result.skipped),
        "discovered": [asdict(item) for item in result.discovered],
        "skipped": [asdict(item) for item in result.skipped],
    }

    print(json.dumps(payload, indent=2, sort_keys=True))


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Discover indexable Markdown files in an Obsidian vault."
    )

    parser.add_argument(
        "root",
        type=Path,
        help="Vault or fixture root to inspect.",
    )

    parser.add_argument(
        "--format",
        choices=("text", "json"),
        default="text",
        help="Output format.",
    )

    parser.add_argument(
        "--follow-symlinks",
        action="store_true",
        help="Follow symbolic links. Disabled by default.",
    )

    return parser


def main(argv: Iterable[str] | None = None) -> int:
    args = build_parser().parse_args(argv)

    try:
        result = discover_markdown(
            args.root,
            follow_symlinks=args.follow_symlinks,
        )
    except (DiscoveryError, OSError) as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1

    if args.format == "json":
        _print_json(result)
    else:
        _print_text(result)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())