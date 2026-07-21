from mcp.server.fastmcp import FastMCP
from personal_ai_mcp.common.adapter import guarded
from .tools import (
    platform_status_tool,
    platform_health_tool,
    platform_versions_tool,
    platform_component_status_tool,
)

mcp = FastMCP("platform-status")

@mcp.tool()
def platform_status() -> dict:
    return guarded(platform_status_tool)

@mcp.tool()
def platform_health() -> dict:
    return guarded(platform_health_tool)

@mcp.tool()
def platform_versions() -> dict:
    return guarded(platform_versions_tool)

@mcp.tool()
def platform_component_status(component: str) -> dict:
    return guarded(lambda: platform_component_status_tool(component))

if __name__ == "__main__":
    mcp.run(transport="stdio")
