#!/bin/bash
#
# doctor.sh
#
# Personal AI Server Health Verification
#
# Runs all platform health checks and provides a unified report.
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

HEALTH_DIR="$SCRIPT_DIR/health"

PASS=0
FAIL=0

GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_banner() {

cat <<EOF

=========================================================
              Personal AI Server Doctor
=========================================================

Date : $(date)

EOF

}

run_check() {

    local script="$1"

    echo
    echo "---------------------------------------------------------"
    echo "Running: $(basename "$script")"
    echo "---------------------------------------------------------"

    if bash "$script"
    then
        ((PASS++))
    else
        ((FAIL++))
    fi
}

summary() {

echo
echo "========================================================="
echo "Overall Summary"
echo "========================================================="
echo

echo "Successful Checks : $PASS"

echo "Failed Checks     : $FAIL"

echo

if [[ $FAIL -eq 0 ]]
then

    echo -e "${GREEN}System Health: PASS${NC}"

    exit 0

else

    echo -e "${RED}System Health: FAIL${NC}"

    exit 1

fi

}

########################################################################

print_banner

CHECKS=(

check-runtime.sh
check-api.sh
check-storage.sh
check-models.sh
check-logs.sh

)

for check in "${CHECKS[@]}"
do

    run_check "$HEALTH_DIR/$check"

done

summary