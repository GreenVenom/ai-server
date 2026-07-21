import pytest

@pytest.fixture
def approved_tools():
    return {
        "obsidian-retrieval__obsidian_get_chunk",
        "obsidian-retrieval__obsidian_list_vaults",
        "obsidian-retrieval__obsidian_retrieval_status",
        "obsidian-retrieval__obsidian_search",
        "platform-status__platform_component_status",
        "platform-status__platform_health",
        "platform-status__platform_status",
        "platform-status__platform_versions",
    }
