import pytest
from personal_ai_mcp.common.validation import validate_safe_id
from personal_ai_mcp.common.errors import ValidationError

@pytest.mark.parametrize(
    "value",
    ["../secret", "/etc/passwd", "a/b", "a\\b", "bad id"],
)
def test_rejects_path_like_identifiers(value):
    with pytest.raises(ValidationError):
        validate_safe_id(value, "value")

def test_accepts_safe_identifier():
    assert (
        validate_safe_id("personal-knowledge", "value")
        == "personal-knowledge"
    )
