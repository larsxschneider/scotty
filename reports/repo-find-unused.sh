#!/usr/bin/env bash
#
# Find repos that have not received any pushes in the past (one year by default).
#
# Usage:
#   repo-find-unused.sh [OPTIONS]
#
# Options:
#   -y, --year             No pushes in a year (default).
#   -m, --month            No pushes in a month.
#   -w, --week             No pushes in a week.
#   -n                     Dry-run; only show what would be done.
#   -h, --help             Display this message.
#
# Example:
#   repo-find-tiny.sh
#

BASE_DIR=$(cd "${0%/*}/.." && pwd)
. "$BASE_DIR/lib-ghe.sh"

# Default constants
INTERVAL='1 YEAR'

while [ $# -gt 0 ]; do
    case $1 in
        (-y|--year)      INTERVAL='1 YEAR'; shift;;
        (-m|--month)     INTERVAL='1 MONTH'; shift;;
        (-w|--week)      INTERVAL='1 WEEK'; shift;;
        (-n) DRY_RUN=1; shift;;
        (-h|--help) usage 2>&1;;
        (--) shift; break;;
        (-*) usage "$1: unknown option";;
        (*) break;;
    esac
done

execute << EOF
    echo "
        SELECT DISTINCT(CONCAT('https://$GHE_HOST/', users.login, '/', repositories.name)) AS repo
        FROM users, repositories
        WHERE
            users.login NOT LIKE 'discarded%' AND
            users.type = 'Organization' AND
            repositories.owner_id = users.id AND
            repositories.created_at < (NOW() - INTERVAL $INTERVAL) AND
            repositories.id NOT IN (
                SELECT DISTINCT(repositories.id)
                FROM pushes, repositories
                WHERE
                    pushes.updated_at > (NOW() - INTERVAL $INTERVAL) AND
                    pushes.repository_id = repositories.id
            )
        ORDER BY repo
    " | ghe-dbconsole -y 2>&1 | sed '1d'
EOF
