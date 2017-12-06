#!/usr/bin/env bash
#
# Print repos:
#   - having more than 1 contributor
#   - located in an an organization (not a personal repo)
#   - having at least 2 pushes in the last 4 weeks
#
# Usage:
#   repo-active.sh [OPTIONS]
#
# Options:
#   -n                     Dry-run; only show what would be done.
#   -h, --help             Display this message.
#
# Example:
#   repo-active.sh
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

execute << EOF
    echo "
        SELECT users.login, repositories.name
        FROM pushes, repositories, users
        WHERE cast(pushes.created_at AS date) BETWEEN (NOW() - INTERVAL 1 MONTH) AND NOW() AND
          pushes.repository_id = repositories.id AND
          repositories.owner_id = users.id AND
          users.type = \"organization\"
        GROUP BY repositories.id
        HAVING COUNT(pushes.pusher_id) > 1
    " | ghe-dbconsole -y
EOF
