#!/usr/bin/env bash
#
# Print audit log of a repo.
#
# Usage:
#   repo-audit.sh [OPTIONS] <org>/<repo>
#
# Options:
#   -n            Dry-run; only show what would be done.
#   -h, --help    Display this message.
#
# Example:
#   repo-audit.sh foo/bar
#

BASE_DIR=$(cd "${0%/*}/.." && pwd)
. "$BASE_DIR/lib-ghe.sh"

while [ $# -gt 0 ]; do
    case $1 in
        (-n) DRY_RUN=1; shift;;
        (-h|--help) usage 2>&1;;
        (--) shift; break;;
        (-*) usage "$1: unknown option";;
        (*) break;;
    esac
done

REPO=$1
if [ -z "$REPO" ]; then
    usage "'Org/Repo' must not be empty."
fi

execute << EOF
    ghe-repo $REPO -c 'cat audit_log'
EOF
