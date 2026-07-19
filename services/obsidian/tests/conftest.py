from __future__ import annotations

import sys
from pathlib import Path

import pytest


REPOSITORY_ROOT = Path(__file__).resolve().parents[3]
SOURCE_ROOT = REPOSITORY_ROOT / "services" / "obsidian" / "src"

if str(SOURCE_ROOT) not in sys.path:
    sys.path.insert(0, str(SOURCE_ROOT))


@pytest.fixture()
def vault_root(tmp_path: Path) -> Path:
    """Create a small synthetic Obsidian vault for unit tests."""
    root = tmp_path / "vault"
    (root / "basic").mkdir(parents=True)
    (root / "excluded").mkdir(parents=True)
    (root / "nested").mkdir(parents=True)

    (root / "basic" / "Platform Overview.md").write_text(
        """---
        aliases:
          - Platform
        tags:
          - platform
          - local-ai
        visibility: private
        ---
        # Platform Overview

        The personal AI platform runs on a Mac mini.

        ## Runtime Components

        OpenClaw provides orchestration, Ollama provides local inference,
        and Qdrant stores embedding vectors.

        See also [[Qdrant Operations#Backup and Restore|Qdrant backups]].
        """.replace("        ", ""),
        encoding="utf-8",
    )

    (root / "basic" / "Docker Startup.md").write_text(
        """# Docker Startup

        Docker Desktop starts after the `openclaw` user logs in.
        """.replace("        ", ""),
        encoding="utf-8",
    )

    (root / "nested" / "Qdrant Operations.md").write_text(
        """---
        tags: [qdrant, operations]
        ---
        # Qdrant Operations

        ## Deployment

        Qdrant runs through Docker Compose.

        ## Backup and Restore

        Collection snapshots are exported with manifests and checksums.
        """.replace("        ", ""),
        encoding="utf-8",
    )

    (root / "excluded" / "Private Note.md").write_text(
        """---
        ai_exclude: true
        ---
        # Private Note

        This fixture must never appear in retrieval results.
        """.replace("        ", ""),
        encoding="utf-8",
    )

    return root


@pytest.fixture()
def parsed_platform(vault_root: Path):
    from obsidian_ingest.parser import parse_document

    return parse_document(
        vault_root / "basic" / "Platform Overview.md",
        root=vault_root,
    )
