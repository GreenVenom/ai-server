from pathlib import Path

from obsidian_ingest.discovery import discover_markdown


def test_discovery_finds_markdown_recursively(vault_root: Path) -> None:
    report = discover_markdown(vault_root)
    relative_paths = {
        Path(item.absolute_path).relative_to(vault_root).as_posix()
        for item in report.discovered
    }

    assert relative_paths == {
        "basic/Docker Startup.md",
        "basic/Platform Overview.md",
        "excluded/Private Note.md",
        "nested/Qdrant Operations.md",
    }


def test_discovery_is_deterministic(vault_root: Path) -> None:
    first = discover_markdown(vault_root)
    second = discover_markdown(vault_root)

    first_paths = [item.relative_path for item in first.discovered]
    second_paths = [item.relative_path for item in second.discovered]

    assert first_paths == second_paths
