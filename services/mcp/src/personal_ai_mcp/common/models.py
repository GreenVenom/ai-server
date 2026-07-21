from typing import Any
from uuid import uuid4
from pydantic import BaseModel, ConfigDict, Field

class StrictModel(BaseModel):
    model_config = ConfigDict(extra="forbid", strict=True)

class ErrorBody(StrictModel):
    code: str
    message: str
    retryable: bool
    request_id: str

class Envelope(StrictModel):
    schema_version: int = 1
    status: str
    request_id: str = Field(default_factory=lambda: str(uuid4()))
    data: Any | None = None
    error: ErrorBody | None = None

def success(data: Any) -> dict[str, Any]:
    return Envelope(status="success", data=data).model_dump()

def failure(code: str, message: str, retryable: bool = False) -> dict[str, Any]:
    request_id = str(uuid4())
    return Envelope(
        status="error",
        request_id=request_id,
        error=ErrorBody(
            code=code,
            message=message,
            retryable=retryable,
            request_id=request_id,
        ),
    ).model_dump()
