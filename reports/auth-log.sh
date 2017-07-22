#!/usr/bin/env bash
#
# Search the authentication log for a specific string and output matching
# lines in the format "<date> <repo> <user> <status> <auth-method>"
#
# Usage:
#   auth-log.sh [OPTIONS] <query>
#
# Options:
#   -a, --all     Process all available logs (rolled logs)
#   -n            Dry-run; only show what would be done.
#   -h, --help    Display this message.
#
# Example:
#   auth-log.sh -a myrepo
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

QUERY=$1
if [ -z "$QUERY" ]; then
    usage "Query must not be empty."
fi

execute << EOF
    zgrep -hF '$QUERY' /var/log/github/gitauth.$LOG |
        perl -lape 's/(?:^.*now="(.{10}).* status=([^ ]+).* member=(?:"user:\d+:)?([^" ]+).* hashed_token=(nil)?.* path=([^ ]+).* proto=([^ ]+).*\$)|.*/\$1 \$5 \$3 \$2 \$6\$4/' |
        sort |
        uniq |
        column -t |
        sed 's/sshnil/ssh/' |
        sed 's/httpnil/http, no token!/'
EOF
