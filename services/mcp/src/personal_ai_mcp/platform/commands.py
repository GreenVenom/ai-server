import os
import subprocess
from dataclasses import dataclass
from personal_ai_mcp.common.limits import (
    DEFAULT_TIMEOUT_SECONDS,
    MAX_STDOUT_CHARS,
    MAX_STDERR_CHARS,
)

@dataclass(frozen=True, slots=True)
class CommandResult:
    returncode: int
    stdout: str
    stderr: str

RESTRICTED_ENV = {
    "PATH": "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin",
    "LANG": "C.UTF-8",
    "LC_ALL": "C.UTF-8",
    "HOME": os.path.expanduser("~"),
}

def run_command(
    argv: list[str],
    timeout: int = DEFAULT_TIMEOUT_SECONDS,
) -> CommandResult:
    completed = subprocess.run(
        argv,
        shell=False,
        check=False,
        capture_output=True,
        text=True,
        timeout=timeout,
        env=RESTRICTED_ENV.copy(),
    )
    return CommandResult(
        completed.returncode,
        completed.stdout[:MAX_STDOUT_CHARS],
        completed.stderr[:MAX_STDERR_CHARS],
    )
