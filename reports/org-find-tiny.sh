#!/usr/bin/env bash
#
# Find orgs that contain less than three repositories.
#
# Usage:
#   org-find-tiny.sh [OPTIONS]
#
# Options:
#   -p, --pusher           Print users that have pushed to repos in tiny orgs.
#   -n                     Dry-run; only show what would be done.
#   -h, --help             Display this message.
#
# Example:
#   org-find-tiny.sh
#

BASE_DIR=$(cd "${0%/*}/.." && pwd)
. "$BASE_DIR/lib-ghe.sh"

while [ $# -gt 0 ]; do
    case $1 in
        (-p|--pusher) PUSHER=1; shift;;
        (-n) DRY_RUN=1; shift;;
        (-h|--help) usage 2>&1;;
        (--) shift; break;;
        (-*) usage "$1: unknown option";;
        (*) break;;
    esac
done

MAX_ORG_COUNT=2

if [ -z $PUSHER ]; then
    execute << EOF
    echo "
        SELECT DISTINCT(CONCAT('https://$GHE_HOST/', users.login)) AS org
        FROM users
        WHERE
            users.type = 'Organization' AND
            users.login NOT LIKE 'restricted%' AND
            users.login NOT LIKE 'discarded%' AND
            $MAX_ORG_COUNT >= (   SELECT COUNT(repositories.name)
                    FROM repositories
                    WHERE repositories.owner_id = users.id
            )
        ORDER BY org
    " | ghe-dbconsole -y 2>&1 | sed '1d'
EOF
else
    execute << EOF
    echo "
        SELECT email, u.login as user, CONCAT('https://$GHE_HOST/', o.login) as org
        FROM users as o, repositories as r, pushes as p, users as u, user_emails as e
        WHERE o.login IN (
            SELECT DISTINCT(u2.login)
            FROM users as u2
            WHERE
                u2.type = 'Organization' AND
                u2.login NOT LIKE 'restricted%' AND
                u2.login NOT LIKE 'discarded%' AND
                $MAX_ORG_COUNT >= (SELECT COUNT(r3.name) FROM repositories as r3 WHERE r3.owner_id = u2.id)
            ) AND
            r.owner_id = o.id AND
            p.repository_id = r.id AND
            p.pusher_id = u.id AND
            u.suspended_at is NULL AND
            u.login not like 'svc-%' AND
            u.id = e.user_id
        GROUP BY u.login, o.login
        ORDER BY u.login, o.login
    " | ghe-dbconsole -y 2>&1 | sed '1d' | column -ts $'\t'
EOF
fi
