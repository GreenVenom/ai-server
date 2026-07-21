import re
from .errors import ValidationError

SAFE_ID = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$")

def validate_safe_id(value: str, field: str) -> str:
    if not SAFE_ID.fullmatch(value):
        raise ValidationError(f"{field} contains unsupported characters.")
    if ".." in value or "/" in value or "\\" in value:
        raise ValidationError(f"{field} must not contain a path.")
    return value
