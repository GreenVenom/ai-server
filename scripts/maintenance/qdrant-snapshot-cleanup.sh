#!/usr/bin/env bash
#
# qdrant-snapshot-cleanup.sh
#
# Cleans both:
#   1. Internal Qdrant collection snapshots
#   2. Portable host snapshot/manifest pairs
#
# Safety defaults:
#   - Dry run enabled
#   - Internal snapshots retained for 7 days
#   - Host backups retained for 30 days
#   - Host snapshot deleted only when its matching manifest exists
#   - Unrelated files are ignored
#
# Compatible with macOS Bash 3.2.
#

set -euo pipefail

readonly QDRANT_URL="${QDRANT_URL:-http://127.0.0.1:6333}"
readonly COLLECTION_NAME="${COLLECTION_NAME:-m04_validation}"

readonly INTERNAL_RETENTION_DAYS="${INTERNAL_RETENTION_DAYS:-7}"
readonly HOST_RETENTION_DAYS="${HOST_RETENTION_DAYS:-30}"

readonly CLEAN_INTERNAL="${CLEAN_INTERNAL:-true}"
readonly CLEAN_HOST="${CLEAN_HOST:-true}"
readonly DRY_RUN="${DRY_RUN:-true}"
readonly FORCE_ORPHAN_DELETE="${FORCE_ORPHAN_DELETE:-false}"

readonly SNAPSHOT_DIR="${SNAPSHOT_DIR:-$HOME/server/backups/qdrant/snapshots}"
readonly MANIFEST_DIR="${MANIFEST_DIR:-$HOME/server/backups/qdrant/manifests}"

PASSED=0
FAILED=0

INTERNAL_DELETE_COUNT=0
INTERNAL_KEEP_COUNT=0
INTERNAL_RECLAIM_BYTES=0

HOST_PAIR_DELETE_COUNT=0
HOST_PAIR_KEEP_COUNT=0
HOST_ORPHAN_COUNT=0
HOST_RECLAIM_BYTES=0

header() {
    printf '\n============================================================\n'
    printf '%s\n' "$1"
    printf '============================================================\n'
}

pass() {
    PASSED=$((PASSED + 1))
    printf 'PASS: %s\n' "$1"
}

fail() {
    FAILED=$((FAILED + 1))
    printf 'FAIL: %s\n' "$1" >&2
}

require_command() {
    if command -v "$1" >/dev/null 2>&1; then
        pass "Required command available: $1"
    else
        fail "Required command missing: $1"
        exit 1
    fi
}

validate_boolean() {
    case "$2" in
        true|false)
            ;;
        *)
            fail "$1 must be true or false"
            exit 1
            ;;
    esac
}

validate_nonnegative_integer() {
    case "$2" in
        ''|*[!0-9]*)
            fail "$1 must be a non-negative integer"
            exit 1
            ;;
    esac
}

human_bytes() {
    python3 - "$1" <<'PY'
import sys

size = int(sys.argv[1])
units = ["B", "KiB", "MiB", "GiB", "TiB"]
value = float(size)

for unit in units:
    if value < 1024 or unit == units[-1]:
        if unit == "B":
            print("{} {}".format(int(value), unit))
        else:
            print("{:.2f} {}".format(value, unit))
        break
    value /= 1024
PY
}

header "Qdrant Snapshot Cleanup"

require_command curl
require_command python3
require_command stat
require_command find

validate_nonnegative_integer \
    "INTERNAL_RETENTION_DAYS" \
    "$INTERNAL_RETENTION_DAYS"

validate_nonnegative_integer \
    "HOST_RETENTION_DAYS" \
    "$HOST_RETENTION_DAYS"

validate_boolean "CLEAN_INTERNAL" "$CLEAN_INTERNAL"
validate_boolean "CLEAN_HOST" "$CLEAN_HOST"
validate_boolean "DRY_RUN" "$DRY_RUN"
validate_boolean "FORCE_ORPHAN_DELETE" "$FORCE_ORPHAN_DELETE"

printf '\nConfiguration\n'
printf '  Qdrant URL             : %s\n' "$QDRANT_URL"
printf '  Collection             : %s\n' "$COLLECTION_NAME"
printf '  Internal retention     : %s days\n' "$INTERNAL_RETENTION_DAYS"
printf '  Host retention         : %s days\n' "$HOST_RETENTION_DAYS"
printf '  Clean internal         : %s\n' "$CLEAN_INTERNAL"
printf '  Clean host             : %s\n' "$CLEAN_HOST"
printf '  Dry run                : %s\n' "$DRY_RUN"
printf '  Force orphan deletion  : %s\n' "$FORCE_ORPHAN_DELETE"
printf '  Snapshot directory     : %s\n' "$SNAPSHOT_DIR"
printf '  Manifest directory     : %s\n' "$MANIFEST_DIR"

if [[ "$CLEAN_INTERNAL" == "true" ]]; then
    header "Internal Qdrant Snapshot Cleanup"

    curl --fail --silent --show-error \
        "${QDRANT_URL}/readyz" >/dev/null
    pass "Qdrant is ready"

    snapshot_response="$(
        curl --fail --silent --show-error \
            "${QDRANT_URL}/collections/${COLLECTION_NAME}/snapshots"
    )"

    internal_plan="$(
        python3 - \
            "$snapshot_response" \
            "$INTERNAL_RETENTION_DAYS" <<'PY'
import json
import sys
from datetime import datetime, timezone, timedelta

data = json.loads(sys.argv[1])
retention_days = int(sys.argv[2])
cutoff = datetime.now(timezone.utc) - timedelta(days=retention_days)

for snapshot in data.get("result", []):
    name = snapshot["name"]
    created = snapshot["creation_time"]

    if created.endswith("Z"):
        created_at = datetime.fromisoformat(
            created.replace("Z", "+00:00")
        )
    else:
        created_at = datetime.fromisoformat(created)
        if created_at.tzinfo is None:
            created_at = created_at.replace(tzinfo=timezone.utc)

    action = "delete" if created_at < cutoff else "keep"

    print(
        "{}|{}|{}|{}".format(
            action,
            name,
            created,
            int(snapshot.get("size", 0)),
        )
    )
PY
    )"

    if [[ -z "$internal_plan" ]]; then
        printf 'No internal snapshots found.\n'
    else
        while IFS='|' read -r action name created size; do
            if [[ "$action" == "delete" ]]; then
                if [[ "$DRY_RUN" == "true" ]]; then
                    printf 'DRY-RUN delete internal: %s created=%s size=%s\n' \
                        "$name" "$created" "$(human_bytes "$size")"
                else
                    curl --fail --silent --show-error \
                        -X DELETE \
                        "${QDRANT_URL}/collections/${COLLECTION_NAME}/snapshots/${name}" \
                        >/dev/null

                    printf 'Deleted internal: %s created=%s size=%s\n' \
                        "$name" "$created" "$(human_bytes "$size")"
                fi

                INTERNAL_DELETE_COUNT=$((INTERNAL_DELETE_COUNT + 1))
                INTERNAL_RECLAIM_BYTES=$((INTERNAL_RECLAIM_BYTES + size))
            else
                printf 'Kept internal: %s created=%s size=%s\n' \
                    "$name" "$created" "$(human_bytes "$size")"

                INTERNAL_KEEP_COUNT=$((INTERNAL_KEEP_COUNT + 1))
            fi
        done <<EOF
$internal_plan
EOF
    fi
fi

if [[ "$CLEAN_HOST" == "true" ]]; then
    header "Portable Host Backup Cleanup"

    mkdir -p "$SNAPSHOT_DIR" "$MANIFEST_DIR"

    host_plan="$(
        python3 - \
            "$SNAPSHOT_DIR" \
            "$MANIFEST_DIR" \
            "$HOST_RETENTION_DAYS" <<'PY'
import os
import sys
from datetime import datetime, timezone, timedelta

snapshot_dir = sys.argv[1]
manifest_dir = sys.argv[2]
retention_days = int(sys.argv[3])
cutoff = datetime.now(timezone.utc) - timedelta(days=retention_days)

snapshot_names = sorted(
    name
    for name in os.listdir(snapshot_dir)
    if name.endswith(".snapshot")
)

for snapshot_name in snapshot_names:
    snapshot_path = os.path.join(snapshot_dir, snapshot_name)
    manifest_path = os.path.join(
        manifest_dir,
        snapshot_name + ".json",
    )

    snapshot_stat = os.stat(snapshot_path)
    modified_at = datetime.fromtimestamp(
        snapshot_stat.st_mtime,
        tz=timezone.utc,
    )

    manifest_exists = os.path.isfile(manifest_path)
    manifest_size = (
        os.stat(manifest_path).st_size
        if manifest_exists
        else 0
    )

    age_action = (
        "delete"
        if modified_at < cutoff
        else "keep"
    )

    print(
        "{}|{}|{}|{}|{}|{}|{}".format(
            age_action,
            snapshot_name,
            snapshot_path,
            manifest_path,
            "true" if manifest_exists else "false",
            snapshot_stat.st_size,
            manifest_size,
        )
    )
PY
    )"

    if [[ -z "$host_plan" ]]; then
        printf 'No portable host snapshots found.\n'
    else
        while IFS='|' read -r \
            action \
            snapshot_name \
            snapshot_path \
            manifest_path \
            manifest_exists \
            snapshot_size \
            manifest_size
        do
            total_size=$((snapshot_size + manifest_size))

            if [[ "$manifest_exists" != "true" ]]; then
                HOST_ORPHAN_COUNT=$((HOST_ORPHAN_COUNT + 1))

                if [[ "$FORCE_ORPHAN_DELETE" == "true" && "$action" == "delete" ]]; then
                    if [[ "$DRY_RUN" == "true" ]]; then
                        printf 'DRY-RUN delete orphan snapshot: %s size=%s\n' \
                            "$snapshot_name" \
                            "$(human_bytes "$snapshot_size")"
                    else
                        rm -f "$snapshot_path"
                        printf 'Deleted orphan snapshot: %s size=%s\n' \
                            "$snapshot_name" \
                            "$(human_bytes "$snapshot_size")"
                    fi

                    HOST_PAIR_DELETE_COUNT=$((HOST_PAIR_DELETE_COUNT + 1))
                    HOST_RECLAIM_BYTES=$((HOST_RECLAIM_BYTES + snapshot_size))
                else
                    printf 'Skipped orphan snapshot: %s manifest missing\n' \
                        "$snapshot_name"
                fi

                continue
            fi

            if [[ "$action" == "delete" ]]; then
                if [[ "$DRY_RUN" == "true" ]]; then
                    printf 'DRY-RUN delete host pair: %s total=%s\n' \
                        "$snapshot_name" \
                        "$(human_bytes "$total_size")"
                else
                    rm -f "$snapshot_path" "$manifest_path"

                    printf 'Deleted host pair: %s total=%s\n' \
                        "$snapshot_name" \
                        "$(human_bytes "$total_size")"
                fi

                HOST_PAIR_DELETE_COUNT=$((HOST_PAIR_DELETE_COUNT + 1))
                HOST_RECLAIM_BYTES=$((HOST_RECLAIM_BYTES + total_size))
            else
                printf 'Kept host pair: %s total=%s\n' \
                    "$snapshot_name" \
                    "$(human_bytes "$total_size")"

                HOST_PAIR_KEEP_COUNT=$((HOST_PAIR_KEEP_COUNT + 1))
            fi
        done <<EOF
$host_plan
EOF
    fi
fi

header "Cleanup Summary"

printf 'Internal snapshots selected : %s\n' "$INTERNAL_DELETE_COUNT"
printf 'Internal snapshots kept     : %s\n' "$INTERNAL_KEEP_COUNT"
printf 'Internal reclaimable space  : %s\n' \
    "$(human_bytes "$INTERNAL_RECLAIM_BYTES")"

printf 'Host pairs selected         : %s\n' "$HOST_PAIR_DELETE_COUNT"
printf 'Host pairs kept             : %s\n' "$HOST_PAIR_KEEP_COUNT"
printf 'Host orphan snapshots       : %s\n' "$HOST_ORPHAN_COUNT"
printf 'Host reclaimable space      : %s\n' \
    "$(human_bytes "$HOST_RECLAIM_BYTES")"

printf 'Dry run                     : %s\n' "$DRY_RUN"

if [[ "$FAILED" -ne 0 ]]; then
    exit 1
fi

printf '\nSnapshot cleanup completed successfully.\n'
