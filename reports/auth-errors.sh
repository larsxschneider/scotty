#!/usr/bin/env bash
#
# Print and count auth errors.
#
# Usage:
#   auth-errors.sh [OPTIONS]
#
# Options:
#   -a, --all     Process all available logs (rolled logs)
#   -n            Dry-run; only show what would be done.
#   -h, --help    Display this message.
#
# Example:
#   auth-errors.sh -a
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
    zcat -f /var/log/github/auth.$LOG |
        grep -v 'at=success' |
        grep -v '"Created user"' |
        grep -v '"Looking for ldap mapping"' |
        grep -v '"Searching for user entry"' |
        grep -v '"user mapped to ldap dn"' |
        perl -nE 'say /at="([^"]+)|at=([^ ]+)/' |
        sort |
        uniq -c |
        sort -n
EOF
