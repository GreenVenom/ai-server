from pathlib import Path

from obsidian_ingest.parser import document_metadata_hash, parse_document


def test_parser_extracts_frontmatter_links_and_headings(vault_root: Path) -> None:
    document = parse_document(
        vault_root / "basic" / "Platform Overview.md",
        root=vault_root,
    )

    assert document.relative_path == "basic/Platform Overview.md"
    assert document.title == "Platform Overview"
    assert document.should_index is True
    assert "platform" in document.tags
    assert "Platform" in document.aliases
    assert any(link.target == "Qdrant Operations" for link in document.wikilinks)
    assert document.source_hash


def test_parser_honors_ai_exclude(vault_root: Path) -> None:
    document = parse_document(
        vault_root / "excluded" / "Private Note.md",
        root=vault_root,
    )

    assert document.should_index is False


def test_metadata_hash_is_stable(vault_root: Path) -> None:
    path = vault_root / "basic" / "Platform Overview.md"
    first = document_metadata_hash(parse_document(path, root=vault_root))
    second = document_metadata_hash(parse_document(path, root=vault_root))

    assert first == second
    assert len(first) == 64
