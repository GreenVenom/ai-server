"""Configuration loading for the Obsidian MCP adapter."""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Any

import yaml

from personal_ai_mcp.common.errors import AuthorizationError, DependencyError


DEFAULT_CONFIG_PATH = Path(
    "/Users/openclaw/server/config/mcp/obsidian.yaml"
)


@dataclass(frozen=True, slots=True)
class RetrievalRuntime:
    executable: str
    module: str
    pythonpath: str
    timeout_seconds: float


@dataclass(frozen=True, slots=True)
class VaultConfig:
    vault_id: str
    collection: str


@dataclass(frozen=True, slots=True)
class ObsidianMCPConfig:
    runtime: RetrievalRuntime
    vaults: dict[str, VaultConfig]

    def require_vault(self, vault_id: str) -> VaultConfig:
        vault = self.vaults.get(vault_id)

        if vault is None:
            raise AuthorizationError(
                "The requested vault is not approved for MCP retrieval."
            )

        return vault


def _require_mapping(value: Any, label: str) -> dict[str, Any]:
    if not isinstance(value, dict):
        raise DependencyError(f"Invalid MCP configuration section: {label}.")

    return value


def load_config(
    path: Path = DEFAULT_CONFIG_PATH,
) -> ObsidianMCPConfig:
    if not path.is_file():
        raise DependencyError("Obsidian MCP configuration is unavailable.")

    try:
        raw = yaml.safe_load(path.read_text(encoding="utf-8"))
    except (OSError, yaml.YAMLError) as exc:
        raise DependencyError(
            "Obsidian MCP configuration could not be read."
        ) from exc

    root = _require_mapping(raw, "root")
    retrieval = _require_mapping(root.get("retrieval"), "retrieval")
    vaults_raw = _require_mapping(root.get("vaults"), "vaults")

    runtime = RetrievalRuntime(
        executable=str(retrieval["executable"]),
        module=str(retrieval["module"]),
        pythonpath=str(retrieval["pythonpath"]),
        timeout_seconds=float(retrieval.get("timeout_seconds", 15)),
    )

    vaults: dict[str, VaultConfig] = {}

    for vault_id, entry in vaults_raw.items():
        vault_data = _require_mapping(entry, f"vaults.{vault_id}")

        if not vault_data.get("enabled", False):
            continue

        vaults[vault_id] = VaultConfig(
            vault_id=vault_id,
            collection=str(vault_data["collection"]),
        )

    return ObsidianMCPConfig(
        runtime=runtime,
        vaults=vaults,
    )