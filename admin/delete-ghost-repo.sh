#!/usr/bin/env bash
#
# Delete unreplicated repo
#
# Usage:
#   delete-ghost-repo.sh <source org/repo>
#
# Options:
#   -h, --help    Display this message.
#
# Example:
#   delete-ghost-repo.sh
#

BASE_DIR=$(cd "${0%/*}/.." && pwd)
. "$BASE_DIR/lib-ghe.sh"

while [ $# -gt 0 ]; do
    case $1 in
        (-h|--help) usage 2>&1;;
        (--) shift; break;;
        (-*) usage "$1: unknown option";;
        (*) break;;
    esac
done

REPO=$1
if [ -z "$REPO" ]; then
    usage "source org/repo is a required parameter!"
fi

execute << EOF
    echo "Repository.find_by_name_with_owner('$REPO').remove(User.find_by_login('ghost'))" | ghe-console -y
EOF
