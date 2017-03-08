#!/usr/bin/env bash
#
# If LDAP is enabled, then HTTP(S) requests against GitHub Enterprise
# via username/password are expensive because every request issues an
# additional request against LDAP.
#
# This script lists the 10 users that made the most username/password
# requests via HTTP(S) recently.
#
# Usage:
#   auth-http-without-token.sh [OPTIONS]
#
# Options:
#   -a, --all     Process all available logs (rolled logs)
#   -n            Dry-run; only show what would be done.
#   -h, --help    Display this message.
#
# Example:
#   auth-errors.sh -a -m
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
    zgrep -hF hashed_token=nil /var/log/github/gitauth.$LOG |
        grep -F proto=http |
        awk '{ print \$8 " " \$10 }' |
        cut -c 8- |
        sort |
        uniq -c |
        sort -n |
        tail |
        column -t
EOF
