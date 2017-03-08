#!/usr/bin/env bash
#
# Print repo and user for all fetches (that includes clones).
#
# Usage:
#   audit-fetches.sh [OPTIONS] [<org>/<repo>]
#
# Options:
#   -a, --all     Process all available logs (rolled logs).
#   -c, --clones  Print clone operations only.
#   -n            Dry-run; only show what would be done.
#   -h, --help    Display this message.
#
# Example:
#   audit-fetches.sh -a --clones foo/bar
#

BASE_DIR=$(cd "${0%/*}/.." && pwd)
. "$BASE_DIR/lib-ghe.sh"

CLONES="tee"

while [ $# -gt 0 ]; do
    case $1 in
        (-a|--all) all_logs; shift;;
        (-c|--clones) CLONES="grep -F -v '\"cloning\":true';"; shift;;
        (-n) DRY_RUN=1; shift;;
        (-h|--help) usage 2>&1;;
        (--) shift; break;;
        (-*) usage "$1: unknown option";;
        (*) break;;
    esac
done

if [ -n "$1" ]; then
    GREP_REPO="grep -i -F $1"
else
    GREP_REPO="tee"
fi

execute << EOF
    zcat -f /var/log/github/audit.$LOG |
        grep -F '"program":"upload-pack"' |
        grep -F '"user_login":' |
        $GREP_REPO |
        $CLONES |
        perl -lape 's/^.*]:(.*)$/\$1/'  |
        jq -r '.repo_name + " " + .user_login' |
        column -t
EOF
