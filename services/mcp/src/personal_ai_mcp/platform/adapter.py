"""Read-only structured inspection of approved platform components."""

from __future__ import annotations

import json
import platform
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Callable

from personal_ai_mcp.obsidian.tools import (
    obsidian_retrieval_status_tool,
)
from personal_ai_mcp.platform.commands import run_command
from personal_ai_mcp.platform.network import (
    endpoint_ready,
    port_open,
    request_json,
)
from personal_ai_mcp.platform.schemas import PlatformComponent


OLLAMA_URL = "http://127.0.0.1:11434"
QDRANT_URL = "http://127.0.0.1:6333"
QDRANT_CONTAINER = "personal-ai-qdrant"
OPENCLAW_GATEWAY_PORT = 18789
OBSIDIAN_COLLECTION = "obsidian_chunks_v2"

PLATFORM_VERSION_FILE = (
    Path.home() / "server/VERSION.md"
)


def utc_now() -> str:
    return (
        datetime.now(timezone.utc)
        .isoformat()
        .replace("+00:00", "Z")
    )


def _state(
    *,
    healthy: bool,
    summary: str,
    details: dict[str, Any] | None = None,
) -> dict[str, Any]:
    return {
        "status": "healthy" if healthy else "unhealthy",
        "healthy": healthy,
        "summary": summary,
        "details": details or {},
    }


def inspect_ollama() -> dict[str, Any]:
    try:
        payload = request_json(f"{OLLAMA_URL}/api/version")
        version = str(payload.get("version", "unknown"))
        ready = True
    except Exception:
        version = "unknown"
        ready = False

    models = run_command(["ollama", "list"])

    installed = []

    if models.returncode == 0:
        installed = [
            line.split()[0]
            for line in models.stdout.splitlines()[1:]
            if line.strip()
        ]

    required = {
        "gemma4:12b",
        "qwen3:14b",
        "nomic-embed-text:latest",
    }

    normalized = {
        value
        if ":" in value
        else f"{value}:latest"
        for value in installed
    }

    missing = sorted(required - normalized)
    healthy = ready and not missing

    return _state(
        healthy=healthy,
        summary=(
            "Ollama API and required models are available."
            if healthy
            else "Ollama is unavailable or models are missing."
        ),
        details={
            "api_ready": ready,
            "version": version,
            "required_models_present": not missing,
            "missing_models": missing,
        },
    )


def inspect_docker() -> dict[str, Any]:
    info = run_command(
        ["docker", "info", "--format", "{{json .ServerVersion}}"]
    )

    healthy = info.returncode == 0

    version = (
        info.stdout.strip().strip('"')
        if healthy
        else "unknown"
    )

    return _state(
        healthy=healthy,
        summary=(
            "Docker engine is available."
            if healthy
            else "Docker engine is unavailable."
        ),
        details={
            "server_version": version,
        },
    )


def inspect_qdrant() -> dict[str, Any]:
    docker = inspect_docker()

    inspect = run_command(
        [
            "docker",
            "inspect",
            QDRANT_CONTAINER,
            "--format",
            (
                "{{.State.Status}}|"
                "{{if .State.Health}}"
                "{{.State.Health.Status}}"
                "{{else}}none{{end}}|"
                "{{.Config.Image}}|"
                "{{.HostConfig.RestartPolicy.Name}}"
            ),
        ]
    )

    values = inspect.stdout.strip().split("|")

    container_status = values[0] if len(values) > 0 else "unknown"
    health_status = values[1] if len(values) > 1 else "unknown"
    image = values[2] if len(values) > 2 else "unknown"
    restart_policy = values[3] if len(values) > 3 else "unknown"

    ready = endpoint_ready(f"{QDRANT_URL}/readyz")

    try:
        root = request_json(QDRANT_URL)
        version = str(root.get("version", "unknown"))
    except Exception:
        version = "unknown"

    try:
        collection = request_json(
            f"{QDRANT_URL}/collections/{OBSIDIAN_COLLECTION}"
        )["result"]
    except Exception:
        collection = {}

    collection_status = collection.get("status", "unknown")
    points = collection.get("points_count")

    healthy = (
        docker["healthy"]
        and inspect.returncode == 0
        and container_status == "running"
        and health_status == "healthy"
        and ready
        and collection_status == "green"
    )

    return _state(
        healthy=healthy,
        summary=(
            "Qdrant container and production collection are healthy."
            if healthy
            else "Qdrant or its production collection is unhealthy."
        ),
        details={
            "version": version,
            "container_status": container_status,
            "container_health": health_status,
            "image": image,
            "restart_policy": restart_policy,
            "rest_ready": ready,
            "grpc_ready": port_open("127.0.0.1", 6334),
            "collection": OBSIDIAN_COLLECTION,
            "collection_status": collection_status,
            "collection_points": points,
        },
    )


def inspect_openclaw() -> dict[str, Any]:
    version_result = run_command(["openclaw", "--version"])
    status_result = run_command(["openclaw", "status", "--all"])

    status_text = (
        status_result.stdout
        + "\n"
        + status_result.stderr
    )

    gateway_active = (
        "loaded" in status_text.lower()
        and "running" in status_text.lower()
    )

    gateway_reachable = (
        "reachable" in status_text.lower()
        or "connectivity probe passed" in status_text.lower()
    )

    port_ready = port_open(
        "127.0.0.1",
        OPENCLAW_GATEWAY_PORT,
    )

    healthy = (
        version_result.returncode == 0
        and status_result.returncode == 0
        and gateway_active
        and gateway_reachable
        and port_ready
    )

    return _state(
        healthy=healthy,
        summary=(
            "OpenClaw gateway is active and reachable."
            if healthy
            else "OpenClaw gateway is unavailable or unhealthy."
        ),
        details={
            "version": (
                version_result.stdout.strip()
                if version_result.returncode == 0
                else "unknown"
            ),
            "gateway_active": gateway_active,
            "gateway_reachable": gateway_reachable,
            "gateway_port_ready": port_ready,
            "binding": "127.0.0.1:18789",
        },
    )


def inspect_obsidian() -> dict[str, Any]:
    response = obsidian_retrieval_status_tool(
        vault_id="personal-knowledge"
    )

    success = response.get("status") == "success"
    data = response.get("data") or {}
    healthy = success and data.get("healthy") is True

    safe_vaults = []

    for vault in data.get("vaults", []):
        safe_vaults.append(
            {
                "vault_id": vault.get("vault_id"),
                "collection": vault.get("collection"),
                "collection_status": vault.get(
                    "collection_status"
                ),
                "document_count": vault.get("document_count"),
                "chunk_count": vault.get(
                    "manifest_chunk_count"
                ),
                "reconciled": vault.get("reconciled"),
                "manifest_generated_at": vault.get(
                    "manifest_generated_at"
                ),
            }
        )

    return _state(
        healthy=healthy,
        summary=(
            "Obsidian retrieval index is reconciled."
            if healthy
            else "Obsidian retrieval index is unhealthy."
        ),
        details={
            "vaults": safe_vaults,
        },
    )


def inspect_tailscale() -> dict[str, Any]:
    """Inspect Tailscale without requiring a PATH-installed CLI."""

    process = run_command(
        ["pgrep", "-f", "[T]ailscale"]
    )
    process_running = process.returncode == 0

    candidate_commands = [
        [
            "/opt/homebrew/bin/tailscale",
            "status",
            "--json",
        ],
        [
            "/usr/local/bin/tailscale",
            "status",
            "--json",
        ],
        [
            "/Applications/Tailscale.app/Contents/MacOS/Tailscale",
            "status",
            "--json",
        ],
    ]

    status_result = None
    cli_path = None

    for command in candidate_commands:
        if not Path(command[0]).is_file():
            continue

        try:
            result = run_command(command)
        except Exception:
            continue

        if result.returncode == 0:
            status_result = result
            cli_path = command[0]
            break

    backend_state = "unknown"
    self_online: bool | None = None
    cli_available = status_result is not None

    if status_result is not None:
        try:
            payload = json.loads(status_result.stdout)

            backend_state = str(
                payload.get("BackendState", "unknown")
            )

            self_node = payload.get("Self", {})

            if isinstance(self_node, dict):
                online_value = self_node.get("Online")

                if isinstance(online_value, bool):
                    self_online = online_value
        except json.JSONDecodeError:
            cli_available = False
            cli_path = None

    if cli_available:
        healthy = (
            process_running
            and backend_state == "Running"
            and self_online is not False
        )

        summary = (
            "Tailscale is running and connected."
            if healthy
            else "Tailscale is running but not connected."
        )
    else:
        healthy = process_running

        summary = (
            "Tailscale is running; detailed CLI status is unavailable."
            if healthy
            else "Tailscale is not running."
        )

    return _state(
        healthy=healthy,
        summary=summary,
        details={
            "process_running": process_running,
            "cli_available": cli_available,
            "cli_path": cli_path,
            "backend_state": backend_state,
            "online": self_online,
            "inspection_mode": (
                "cli"
                if cli_available
                else "process-fallback"
            ),
        },
    )


def inspect_mcp() -> dict[str, Any]:
    result = run_command(
        [
            "openclaw",
            "mcp",
            "probe",
            "obsidian-retrieval",
            "--json",
        ]
    )

    tools: list[str] = []
    diagnostics: list[Any] = []
    server_tools = 0

    if result.returncode == 0:
        try:
            payload = json.loads(result.stdout)
            tools = list(payload.get("tools", []))
            diagnostics = list(
                payload.get("diagnostics", [])
            )
            server_tools = int(
                payload.get("servers", {})
                .get("obsidian-retrieval", {})
                .get("tools", 0)
            )
        except (
            json.JSONDecodeError,
            TypeError,
            ValueError,
        ):
            diagnostics = ["invalid probe response"]

    expected = {
        "obsidian-retrieval__obsidian_search",
        "obsidian-retrieval__obsidian_get_chunk",
        "obsidian-retrieval__obsidian_list_vaults",
        "obsidian-retrieval__obsidian_retrieval_status",
    }

    healthy = (
        result.returncode == 0
        and set(tools) == expected
        and server_tools == 4
        and not diagnostics
    )

    return _state(
        healthy=healthy,
        summary=(
            "MCP server exposes the approved tool inventory."
            if healthy
            else "MCP discovery or tool policy is unhealthy."
        ),
        details={
            "server": "obsidian-retrieval",
            "tool_count": server_tools,
            "tools": sorted(tools),
            "diagnostic_count": len(diagnostics),
        },
    )


INSPECTORS: dict[
    PlatformComponent,
    Callable[[], dict[str, Any]],
] = {
    PlatformComponent.OLLAMA: inspect_ollama,
    PlatformComponent.OPENCLAW: inspect_openclaw,
    PlatformComponent.QDRANT: inspect_qdrant,
    PlatformComponent.OBSIDIAN: inspect_obsidian,
    PlatformComponent.DOCKER: inspect_docker,
    PlatformComponent.TAILSCALE: inspect_tailscale,
    PlatformComponent.MCP: inspect_mcp,
}


def inspect_component(
    component: PlatformComponent,
) -> dict[str, Any]:
    return INSPECTORS[component]()


def inspect_all() -> dict[str, Any]:
    components: dict[str, dict[str, Any]] = {}

    for component, inspector in INSPECTORS.items():
        try:
            components[component.value] = inspector()
        except Exception:
            components[component.value] = _state(
                healthy=False,
                summary=(
                    "The component inspection could not be completed."
                ),
                details={
                    "inspection_error": True,
                },
            )

    healthy = all(
        item["healthy"]
        for item in components.values()
    )

    return {
        "overall": "healthy" if healthy else "unhealthy",
        "healthy": healthy,
        "checked_at": utc_now(),
        "hostname": platform.node(),
        "components": components,
    }
