#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

"$SCRIPT_DIR/check-runtime.sh"
"$SCRIPT_DIR/check-api.sh"
"$SCRIPT_DIR/check-storage.sh"
"$SCRIPT_DIR/check-models.sh"
"$SCRIPT_DIR/check-logs.sh"