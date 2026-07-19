from __future__ import annotations

from pathlib import Path

import obsidian_ingest.incremental as incremental


def test_incremental_cli_contract(vault_root: Path) -> None:
    parser = incremental.build_parser()
    args = parser.parse_args(
        [
            str(vault_root),
            "--vault-id",
            "m05-fixture",
            "--collection",
            "obsidian_chunks_v1",
        ]
    )

    assert args.root == vault_root
    assert args.vault_id == "m05-fixture"
    assert args.collection == "obsidian_chunks_v1"


def test_incremental_module_exposes_safe_reconciliation_entry_point() -> None:
    supported = (
        "incremental_index",
        "reconcile_index",
        "run_incremental_index",
    )
    assert any(callable(getattr(incremental, name, None)) for name in supported)
