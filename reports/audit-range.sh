#!/usr/bin/env bash
#
# Print the date range of the audit log.
#
# Usage:
#   audit-range.sh [OPTIONS]
#
# Options:
#   -a, --all     Process all available logs (rolled logs).
#   -n            Dry-run; only show what would be done.
#   -h, --help    Display this message.
#
# Example:
#   audit-range.sh -a
#

BASE_DIR=$(cd "${0%/*}/.." && pwd)
. "$BASE_DIR/lib-ghe.sh"

while [ $# -gt 0 ]; do
    case $1 in
        (-a|--all) all_logs; shift;;
        (-n) DRY_RUN=1; shift;;
        (-h|--help) usage 2>&1;;
        (--) shift; break;;
        (-*) usage "$1: unknown option";;
        (*) break;;
    esac
done

execute << EOF
    FIRST_LOG=\$(ls /var/log/github/audit.$LOG | sort | tail -n 1)
    FIRST_LINE=\$(zcat -f \$FIRST_LOG | head -n 1 | cut -c -16)
    LAST_LOG=\$(ls /var/log/github/audit.$LOG | sort | head -n 1)
    LAST_LINE=\$(zcat -f \$LAST_LOG | tail -n 1 | cut -c -16)
    echo "Data since: \$FIRST_LINE"
    echo "Data until: \$LAST_LINE"
EOF
