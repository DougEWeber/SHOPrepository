#!/usr/bin/env bash
#
# Test runner for the SHOPrepository 5250 test suite (INVMAINT, VNDMAINT,
# POMAINT, CUSTMAINT). Each test is a standalone expect script that
# signs on to the iSeries over telnet, drives one function of one
# command, and prints "PASS: <name> -- <detail>" or "FAIL: <name> --
# <reason>" plus the last screen buffer on failure.
#
# Usage:
#   ./run.sh                  run every test, print a pass/fail summary
#   ./run.sh inv_add vnd_add  run only the named test(s)
#   ./run.sh --list           list all available tests
#   ./run.sh --verbose ...    show full raw session output for each test
#
# Environment overrides (see config.exp): HOST, PORT, SHOPUSER, SHOPPASS, SHOPLIB

set -o pipefail
cd "$(dirname "$0")"

usage() {
    cat <<EOF
Usage: ./run.sh [options] [test_name ...]

  (no test names)   run every test in this directory
  test_name ...     run only the named test(s), e.g. ./run.sh inv_add vnd_view
  --list            list all available test names and exit
  --verbose         print full raw session output for each test as it runs
  -h, --help        show this help

Environment overrides:
  HOST=...      telnet host      (default services-us-virginia-m-1.skytap.com)
  PORT=...      telnet port      (default 8209)
  SHOPUSER=...  sign-on user     (default gittest)
  SHOPPASS=...  sign-on password (default gittest)
  SHOPLIB=...   library to ADDLIBLE before running commands (default SHOPDEWOBJ)
EOF
}

ALL_TESTS=()
while IFS= read -r line; do
    [ -n "$line" ] && ALL_TESTS+=("$line")
done < <(ls -- *.exp 2>/dev/null | grep -v -E '^(lib|config)\.exp$' | sed 's/\.exp$//' | sort)

VERBOSE=0
TESTS=()
for arg in "$@"; do
    case "$arg" in
        -h|--help) usage; exit 0 ;;
        --list)
            printf '%s\n' "${ALL_TESTS[@]}"
            exit 0
            ;;
        --verbose) VERBOSE=1 ;;
        *) TESTS+=("$arg") ;;
    esac
done

if [ ${#TESTS[@]} -eq 0 ]; then
    TESTS=("${ALL_TESTS[@]}")
fi

PASS_COUNT=0
FAIL_COUNT=0
FAILED_NAMES=()

for t in "${TESTS[@]}"; do
    if [ ! -f "$t.exp" ]; then
        echo "SKIP: $t (no such test -- $t.exp not found; see ./run.sh --list)"
        continue
    fi

    printf '%-32s ' "$t"
    OUT=$(/usr/bin/expect "$t.exp" 2>&1)

    if [ "$VERBOSE" -eq 1 ]; then
        echo
        echo "$OUT"
        echo
    fi

    RESULT_LINE=$(echo "$OUT" | grep -oE '(PASS|FAIL): [^"]*' | tail -1)

    if echo "$RESULT_LINE" | grep -q '^PASS:'; then
        echo "PASS  -- ${RESULT_LINE#PASS: $t -- }"
        PASS_COUNT=$((PASS_COUNT + 1))
    else
        echo "FAIL"
        FAIL_COUNT=$((FAIL_COUNT + 1))
        FAILED_NAMES+=("$t")
        if [ "$VERBOSE" -eq 0 ]; then
            echo "$OUT" | tail -20 | sed 's/^/    /'
        fi
    fi
done

echo
echo "----------------------------------------------------------------"
echo "Passed: $PASS_COUNT   Failed: $FAIL_COUNT   Total: $((PASS_COUNT + FAIL_COUNT))"

if [ "$FAIL_COUNT" -gt 0 ]; then
    echo "Failed: ${FAILED_NAMES[*]}"
    echo
    echo "To diagnose a failing test, re-run it alone with full output, e.g.:"
    echo "  ./run.sh --verbose ${FAILED_NAMES[0]}"
    exit 1
fi

exit 0
