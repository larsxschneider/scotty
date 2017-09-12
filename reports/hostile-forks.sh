#!/usr/bin/env bash
#
# Print potentially hostile forks. These are forks in an organization
# with a parent in an organization.
#
# Usage:
#   hostile-forks.sh [OPTIONS]
#
# Options:
#   -n                     Dry-run; only show what would be done.
#   -h, --help             Display this message.
#
# Example:
#   hostile-forks.sh
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

echo "## Potentially hostile forks: "
execute << EOF
    echo "
        SELECT CONCAT('https://$GHE_HOST/', org.login, '/', repo.name)
        FROM users as org_parent, users as org, repositories as repo, repositories as repo_parent
        WHERE
            org.login NOT LIKE 'discarded%' AND
            repo.name NOT LIKE 'discarded%' AND
            org_parent.login NOT LIKE 'discarded%' AND
            org.type = 'Organization' AND
            org_parent.type = 'Organization' AND
            repo.owner_id = org.id AND
            repo_parent.id = repo.parent_id AND
            repo_parent.owner_id = org_parent.id
        ORDER BY org.login, repo.name
    " | ghe-dbconsole -y 2>&1 | sed '1,2d'
EOF

