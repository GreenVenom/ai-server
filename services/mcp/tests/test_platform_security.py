import inspect
import pytest
from pydantic import ValidationError as PydanticValidationError
from personal_ai_mcp.platform.commands import (
    run_command,
    RESTRICTED_ENV,
)
from personal_ai_mcp.platform.schemas import ComponentStatusRequest

@pytest.mark.parametrize(
    "component",
    ["whoami", "../../bin/sh", "/bin/ls", "qdrant;id"],
)
def test_component_allowlist_rejects_unknown_values(component):
    with pytest.raises(PydanticValidationError):
        ComponentStatusRequest(component=component)

def test_unknown_fields_rejected():
    with pytest.raises(PydanticValidationError):
        ComponentStatusRequest(
            component="qdrant",
            command="whoami",
        )

def test_run_command_does_not_use_shell():
    assert "shell=False" in inspect.getsource(run_command)

def test_restricted_environment_is_small():
    assert set(RESTRICTED_ENV) == {
        "PATH",
        "LANG",
        "LC_ALL",
        "HOME",
    }
