#!/usr/bin/env bash
#
# This script prints the Git client versions sorted by the number of IP
# addresses that have used this version recently.
#
# Usage:
#   git-versions.sh
#
# Options:
#   -a, --all     Process all available logs (rolled logs
#   -n            Dry-run; only show what would be done.
#   -h, --help    Display this message.
#
# Example:
#   git-versions.sh
#

BASE_DIR=$(cd "${0%/*}/.." && pwd)
. "$BASE_DIR/lib-ghe.sh"

while [ $# -gt 0 ]; do
    case $1 in
        (-a|--all)      all_logs; shift;;
        (-h|--help)     usage 2>&1;;
        (-n)            DRY_RUN=1; shift;;
        (--)            shift; break;;
        (-*)            usage "$1: unknown option";;
        (*) break;;
    esac
done

execute << EOF
    zgrep -hF '||' /var/log/haproxy.$LOG |
        perl -lape 's/.* (.*):.* \[.*\|\|([^}]*).*/\$1 \$2/' |
        sort |
        uniq |
        perl -lape 's/[^ ]+ //' |
        grep -E '^git/' |
        sort |
        uniq -c |
        sort -n -r
EOF
