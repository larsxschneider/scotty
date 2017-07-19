#!/usr/bin/env bash
#
# Find users that have pushed to repos in an org in the past (one year by default).
#
# Usage:
#   org-pushers.sh [OPTIONS]
#
# Options:
#   -y, --year             No pushes in a year (default).
#   -m, --month            No pushes in a month.
#   -w, --week             No pushes in a week.
#   -n                     Dry-run; only show what would be done.
#   -h, --help             Display this message.
#
# Example:
#   org-pushers.sh
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

ORG=$1
if [ -z "$ORG" ]; then
    usage "Org must not be empty."
fi

execute << EOF
    echo "
    SELECT
        CONCAT('https://$GHE_HOST/', org.login, '/', repositories.name) AS repo,
        pusher.login AS user,
        pushes.updated_at AS 'last push date'
    FROM pushes, repositories, users AS org, users AS pusher
    WHERE
        pushes.pusher_id = pusher.id AND
        pushes.updated_at > (NOW() - INTERVAL $INTERVAL) AND
        pushes.repository_id = repositories.id AND
        repositories.owner_id = org.id AND
        org.login = '$ORG' AND
        org.type = 'Organization'
    GROUP BY  repositories.name, pusher.login
    ORDER BY  repositories.name, pusher.login
    " | ghe-dbconsole -y 2>&1 | sed '1d' | column -ts $'\t'
EOF
