import pytest
from personal_ai_mcp.platform.tools import (
    platform_component_status_tool,
)

@pytest.mark.integration
def test_qdrant_component_live():
    result = platform_component_status_tool("qdrant")
    assert result["status"] == "success"
    assert (
        result["data"]["details"]["collection"]
        == "obsidian_chunks_v1"
    )
