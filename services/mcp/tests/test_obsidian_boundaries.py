import pytest
from personal_ai_mcp.obsidian.tools import _approve_vault
from personal_ai_mcp.common.errors import (
    AuthorizationError,
    ValidationError,
)

def test_only_production_vault_is_approved():
    assert (
        _approve_vault("personal-knowledge")
        == "personal-knowledge"
    )

@pytest.mark.parametrize(
    "vault",
    ["other", "../../.ssh", "/Users/openclaw"],
)
def test_unapproved_vaults_are_rejected(vault):
    with pytest.raises((AuthorizationError, ValidationError)):
        _approve_vault(vault)
