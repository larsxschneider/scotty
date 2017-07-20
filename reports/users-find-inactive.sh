#!/usr/bin/env bash
#
# Find users without activity.
#
# Please note: User that *only* read content are not well captured!
#
# Usage:
#   users-find-inactive.sh [OPTIONS]
#
# Options:
#   -y, --year             No activity in a year.
#   -3m, --3month          No activity in a 3 months (default).
#   -m, --month            No activity in a month.
#   -n                     Dry-run; only show what would be done.
#   -h, --help             Display this message.
#
# Example:
#   users-find-inactive.sh
#

BASE_DIR=$(cd "${0%/*}/.." && pwd)
. "$BASE_DIR/lib-ghe.sh"

# Default constants
INTERVAL='3 MONTH'

while [ $# -gt 0 ]; do
    case $1 in
        (-y|--year)       INTERVAL='1 YEAR'; shift;;
        (-3m|--3month)    INTERVAL='3 MONTH'; shift;;
        (-m|--month)      INTERVAL='1 MONTH'; shift;;
        (-n) DRY_RUN=1; shift;;
        (-h|--help) usage 2>&1;;
        (--) shift; break;;
        (-*) usage "$1: unknown option";;
        (*) break;;
    esac
done

execute << EOF
    AUTH_USERS=\$(
        zgrep -hoP 'user_id=[^ ]*' /var/log/github/auth.* |
        cut -c9- |
        grep -Fv 'nil' |
        sort -n |
        uniq |
        perl -pe 's/(.+)\n\$/\$1,/' |
        perl -pe 's/,\$//'
    )
    echo "
        SELECT login
        FROM users
        WHERE
            users.type = 'User' AND
            suspended_at IS NULL AND
            users.id NOT IN (\$AUTH_USERS) AND
            created_at < (NOW() - INTERVAL 1 WEEK) AND
            users.id NOT IN (SELECT DISTINCT(pusher_id) FROM pushes WHERE updated_at > (NOW() - INTERVAL $INTERVAL)) AND
            users.id NOT IN (SELECT DISTINCT(user_id) FROM commit_comments WHERE updated_at > (NOW() - INTERVAL $INTERVAL)) AND
            users.id NOT IN (SELECT DISTINCT(user_id) FROM issue_comments WHERE updated_at > (NOW() - INTERVAL $INTERVAL)) AND
            users.id NOT IN (SELECT DISTINCT(user_id) FROM oauth_accesses WHERE updated_at > (NOW() - INTERVAL $INTERVAL)) AND
            users.id NOT IN (SELECT DISTINCT(user_id) FROM oauth_authorizations WHERE updated_at > (NOW() - INTERVAL $INTERVAL)) AND
            users.id NOT IN (SELECT DISTINCT(user_id) FROM pull_request_review_comments WHERE updated_at > (NOW() - INTERVAL $INTERVAL)) AND
            users.id NOT IN (SELECT DISTINCT(user_id) FROM pull_request_reviews WHERE updated_at > (NOW() - INTERVAL $INTERVAL))
        ORDER BY 1;
    " | ghe-dbconsole -y 2>&1 | sed '1d'
EOF
