#!/usr/bin/env bash
#
# Remove orphaned objects from a Git repo on GHE. This is necessary if
# sensitive data was removed following this tutorial:
# https://help.github.com/enterprise/2.8/user/articles/removing-sensitive-data-from-a-repository/
#
# Finally memcached is restarted to remove cached views.
#
# Usage:
#   repo-remove-sensitive-data.sh [OPTIONS] <org>/<repo>
#
# Options:
#   -n            Dry-run; only show what would be done.
#   -h, --help    Display this message.
#
# Example:
#   repo-remove-sensitive-data.sh foo/bar
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

warning "This script restarts GHE services!"

execute << EOF
    ghe-repo-gc --prune $REPO
    sudo service memcached restart
EOF
