#!/usr/bin/env bash
#
# Show the number of API calls made where a rate limit has
# been exceeded, grouped by rate limit key.
#
# Usage:
#   rate-limit-report.sh [OPTIONS]
#
# Options:
#   -a, --all     Process all available logs (rolled logs)
#   -n            Dry-run; only show what would be done.
#   -h, --help    Display this message.
#
# Example:
#   rate-limit-report.sh
#

BASE_DIR=$(cd "${0%/*}/.." && pwd)
. "$BASE_DIR/lib-ghe.sh"

while [ $# -gt 0 ]; do
    case $1 in
        (-a|--all)      all_logs; shift;;
        (-n)            DRY_RUN=1; shift;;
        (-h|--help)     usage 2>&1;;
        (--)            shift; break;;
        (-*)            usage "$1: unknown option";;
        (*) break;;
    esac
done

execute << EOF
    zgrep "rate_limit_remaining=0" /var/log/github/unicorn.$LOG |
        grep -oP "rate_limit_key=\K[^ ]*" |
        sort |
        uniq -c |
        sort -rn
EOF
