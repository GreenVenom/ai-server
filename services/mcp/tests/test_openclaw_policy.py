import json
import subprocess
import pytest

EXPECTED = {
    "obsidian-retrieval__obsidian_get_chunk",
    "obsidian-retrieval__obsidian_list_vaults",
    "obsidian-retrieval__obsidian_retrieval_status",
    "obsidian-retrieval__obsidian_search",
    "platform-status__platform_component_status",
    "platform-status__platform_health",
    "platform-status__platform_status",
    "platform-status__platform_versions",
}

@pytest.mark.integration
def test_live_openclaw_probe_has_exact_inventory():
    payload = json.loads(
        subprocess.check_output(
            ["openclaw", "mcp", "probe", "--json"],
            text=True,
        )
    )
    assert set(payload["servers"]) == {
        "obsidian-retrieval",
        "platform-status",
    }
    assert set(payload["tools"]) == EXPECTED
    assert payload["diagnostics"] == []
