"""Read-only production-manifest access."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from personal_ai_mcp.common.errors import DependencyError
from personal_ai_mcp.obsidian.config import VaultConfig


def load_manifest(vault: VaultConfig) -> dict[str, Any]:
    path = Path(vault.manifest)

    if not path.is_file():
        raise DependencyError(
            "The Obsidian index manifest is unavailable."
        )

    try:
        manifest = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise DependencyError(
            "The Obsidian index manifest could not be read."
        ) from exc

    if not isinstance(manifest, dict):
        raise DependencyError(
            "The Obsidian index manifest is invalid."
        )

    if manifest.get("vault_id") != vault.vault_id:
        raise DependencyError(
            "The Obsidian index manifest vault identity is invalid."
        )

    if manifest.get("collection") != vault.collection:
        raise DependencyError(
            "The Obsidian index manifest collection is invalid."
        )

    documents = manifest.get("documents")

    if not isinstance(documents, dict):
        raise DependencyError(
            "The Obsidian index manifest document inventory is invalid."
        )

    return manifest


def manifest_chunk_ids(
    manifest: dict[str, Any],
) -> set[str]:
    chunk_ids: set[str] = set()

    documents = manifest.get("documents", {})

    for document in documents.values():
        if not isinstance(document, dict):
            continue

        values = document.get("chunk_ids", [])

        if not isinstance(values, list):
            continue

        chunk_ids.update(
            str(value)
            for value in values
        )

    return chunk_ids