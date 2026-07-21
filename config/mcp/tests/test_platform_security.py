"""Security-boundary tests for Platform Status MCP."""

from __future__ import annotations

import subprocess

import pytest

from personal_ai_mcp.platform import commands
from personal_ai_mcp.platform.commands import CommandResult
from personal_ai_mcp.platform.schemas import (
    ComponentStatusRequest,
)
from personal_ai_mcp.platform.tools import (
    platform_component_status_tool,
)


@pytest.mark.parametrize(
    "component",
    [
        "restart-qdrant",
        "qdrant; whoami",
        "$(id)",
        "../../../bin/sh",
        "/bin/sh",
        "docker",
        "Docker",
        "",
    ],
)
def test_component_allowlist_rejects_unapproved_values(
    component: str,
) -> None:
    response = platform_component_status_tool(
        component=component,
    )

    assert response["status"] == "error"
    assert response["error"]["code"] == "MCP-VALIDATION"


def test_component_schema_rejects_unknown_field() -> None:
    with pytest.raises(ValueError):
        ComponentStatusRequest.model_validate(
            {
                "component": "qdrant",
                "command": "docker restart personal-ai-qdrant",
            }
        )


def test_command_runner_never_uses_shell(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    captured: dict[str, object] = {}

    def fake_run(*args, **kwargs):
        captured["args"] = args
        captured["kwargs"] = kwargs

        return subprocess.CompletedProcess(
            args=args[0],
            returncode=0,
            stdout="ok",
            stderr="",
        )

    monkeypatch.setattr(
        commands.subprocess,
        "run",
        fake_run,
    )

    result = commands.run_command(
        ["openclaw", "--version"]
    )

    assert isinstance(result, CommandResult)
    assert result.returncode == 0
    assert captured["kwargs"]["shell"] is False
    assert captured["args"][0] == [
        "openclaw",
        "--version",
    ]


def test_command_runner_uses_restricted_environment(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    captured: dict[str, object] = {}

    def fake_run(*args, **kwargs):
        captured["environment"] = kwargs["env"]

        return subprocess.CompletedProcess(
            args=args[0],
            returncode=0,
            stdout="ok",
            stderr="",
        )

    monkeypatch.setattr(
        commands.subprocess,
        "run",
        fake_run,
    )

    commands.run_command(["docker", "info"])

    environment = captured["environment"]

    assert set(environment) == {
        "HOME",
        "PATH",
        "LANG",
        "LC_ALL",
    }

    assert environment["LANG"] == "C"
    assert environment["LC_ALL"] == "C"


def test_command_output_is_bounded(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    def fake_run(*args, **kwargs):
        return subprocess.CompletedProcess(
            args=args[0],
            returncode=0,
            stdout="x" * 30_000,
            stderr="y" * 10_000,
        )

    monkeypatch.setattr(
        commands.subprocess,
        "run",
        fake_run,
    )

    result = commands.run_command(
        ["openclaw", "--version"]
    )

    assert len(result.stdout) == 20_000
    assert len(result.stderr) == 4_000