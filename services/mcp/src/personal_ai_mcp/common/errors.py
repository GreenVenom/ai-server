from dataclasses import dataclass

@dataclass(slots=True)
class MCPServiceError(Exception):
    code: str
    message: str
    retryable: bool = False

    def __str__(self) -> str:
        return self.message

class ValidationError(MCPServiceError):
    def __init__(self, message: str = "The request is invalid.") -> None:
        super().__init__("MCP-VALIDATION", message, False)

class AuthorizationError(MCPServiceError):
    def __init__(self, message: str = "The request is outside the approved boundary.") -> None:
        super().__init__("MCP-AUTHORIZATION", message, False)

class DependencyError(MCPServiceError):
    def __init__(self, message: str, retryable: bool = True) -> None:
        super().__init__("MCP-DEPENDENCY", message, retryable)
