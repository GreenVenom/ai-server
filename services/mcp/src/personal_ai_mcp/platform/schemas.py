from typing import Literal
from personal_ai_mcp.common.models import StrictModel

ComponentName = Literal[
    "ollama",
    "openclaw",
    "qdrant",
    "obsidian",
    "docker",
    "tailscale",
    "mcp",
]

class ComponentStatusRequest(StrictModel):
    component: ComponentName
