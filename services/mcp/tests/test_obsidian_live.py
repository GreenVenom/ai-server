import pytest
from personal_ai_mcp.obsidian.tools import (
    obsidian_retrieval_status_tool,
)

@pytest.mark.integration
def test_production_vault_reconciled():
    result = obsidian_retrieval_status_tool(
        "personal-knowledge"
    )
    assert result["status"] == "success"
    assert result["data"]["reconciled"] is True
    assert result["data"]["missing_points"] == 0
    assert result["data"]["orphan_points"] == 0
