import json
import platform
import urllib.request
from typing import Any
from personal_ai_mcp.common.errors import DependencyError, ValidationError
from personal_ai_mcp.common.models import success
from .commands import run_command
from .schemas import ComponentStatusRequest

QDRANT_URL = "http://127.0.0.1:6333"
COLLECTION = "obsidian_chunks_v1"

def _json_url(url: str) -> dict[str, Any]:
    try:
        with urllib.request.urlopen(url, timeout=10) as response:
            return json.load(response)
    except Exception as exc:
        raise DependencyError("A local dependency is unavailable.") from exc

def _version(argv: list[str]) -> str:
    result = run_command(argv)
    value = (result.stdout or result.stderr).strip()
    return value.splitlines()[0] if result.returncode == 0 and value else "unknown"

def platform_versions_tool() -> dict[str, Any]:
    return success({
        "openclaw": _version(["openclaw", "--version"]),
        "ollama": _version(["ollama", "--version"]),
        "docker": _version(["docker", "--version"]),
        "system_python": _version(["python3", "--version"]),
        "tailscale": _version(["tailscale", "version"]),
        "qdrant": _json_url(QDRANT_URL + "/").get("version", "unknown"),
        "mcp_runtime": platform.python_version(),
    })

def _qdrant_details() -> dict[str, Any]:
    metadata = _json_url(
        f"{QDRANT_URL}/collections/{COLLECTION}"
    )["result"]
    inspect = run_command(["docker", "inspect", "personal-ai-qdrant"])
    status = health = image = restart = "unknown"
    if inspect.returncode == 0:
        data = json.loads(inspect.stdout)[0]
        state = data.get("State", {})
        status = state.get("Status", "unknown")
        health = state.get("Health", {}).get("Status", "unknown")
        image = data.get("Config", {}).get("Image", "unknown")
        restart = (
            data.get("HostConfig", {})
            .get("RestartPolicy", {})
            .get("Name", "unknown")
        )
    return {
        "version": _json_url(QDRANT_URL + "/").get("version", "unknown"),
        "container_status": status,
        "container_health": health,
        "image": image,
        "restart_policy": restart,
        "rest_ready": True,
        "grpc_ready": True,
        "collection": COLLECTION,
        "collection_status": metadata.get("status"),
        "collection_points": metadata.get("points_count"),
    }

def platform_component_status_tool(component: str) -> dict[str, Any]:
    try:
        request = ComponentStatusRequest(component=component)
    except Exception as exc:
        raise ValidationError(
            "The platform inspection request is invalid."
        ) from exc

    if request.component == "qdrant":
        details = _qdrant_details()
        healthy = (
            details["container_status"] == "running"
            and details["collection_status"] == "green"
        )
        return success({
            "component": "qdrant",
            "status": "healthy" if healthy else "degraded",
            "healthy": healthy,
            "summary": (
                "Qdrant container and production collection are healthy."
                if healthy
                else "Qdrant requires attention."
            ),
            "details": details,
        })

    health = platform_health_tool()["data"]["components"][request.component]
    return success({"component": request.component, **health})

def platform_health_tool() -> dict[str, Any]:
    checks = {
        "ollama": run_command(["pgrep", "-x", "ollama"]).returncode == 0,
        "openclaw": run_command(
            ["openclaw", "gateway", "status"]
        ).returncode == 0,
        "qdrant": _qdrant_details()["collection_status"] == "green",
        "obsidian": True,
        "docker": run_command(["docker", "info"]).returncode == 0,
        "tailscale": run_command(
            ["pgrep", "-f", "Tailscale"]
        ).returncode == 0,
        "mcp": True,
    }
    components = {
        name: {
            "status": "healthy" if healthy else "unhealthy",
            "healthy": healthy,
        }
        for name, healthy in checks.items()
    }
    return success({
        "healthy": all(checks.values()),
        "components": components,
    })

def platform_status_tool() -> dict[str, Any]:
    return platform_health_tool()
