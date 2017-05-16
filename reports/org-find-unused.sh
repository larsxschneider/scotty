#!/usr/bin/env bash
#
# Find orgs that have not received any pushes in the past (one year by default).
#
# Usage:
#   org-find-unused.sh [OPTIONS]
#
# Options:
#   -y, --year             No pushes in a year (default).
#   -m, --month            No pushes in a month.
#   -w, --week             No pushes in a week.
#   -n                     Dry-run; only show what would be done.
#   -h, --help             Display this message.
#
# Example:
#   org-find-tiny.sh
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
        SELECT DISTINCT(CONCAT('https://$GHE_HOST/', users.login)) AS org
        FROM users
        WHERE
            users.type = 'Organization' AND
            users.login NOT LIKE 'restricted%' AND
            users.login NOT LIKE 'discarded%' AND
            users.id NOT IN (
                SELECT
                DISTINCT(users.id)
                FROM pushes, users, repositories
                WHERE
                    pushes.updated_at > (NOW() - INTERVAL $INTERVAL) AND
                    repositories.owner_id = users.id AND
                    pushes.repository_id = repositories.id AND
                    users.type = 'Organization'
               )
        ORDER BY org
    " | ghe-dbconsole -y 2>&1 | sed '1d'
EOF
