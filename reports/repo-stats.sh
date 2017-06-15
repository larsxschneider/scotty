#!/usr/bin/env bash
#
# Print instance-wide statistics on repository content
#
# Usage:
#   repo-stats.sh [OPTIONS]
#
# Options:
#   -n                     Dry-run; only show what would be done.
#   -h, --help             Display this message.
#
# Example:
#   repo-stats.sh
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

echo "## TOP 10 languages used on $GHE_HOST"
execute << EOF
    echo "
        SELECT language_names.name AS 'Language', COUNT(languages.repository_id) AS '# Repos'
        FROM languages, language_names
        WHERE languages.language_name_id = language_names.id
        GROUP BY 1
        ORDER BY 2 DESC
        LIMIT 10
    " | ghe-dbconsole -y 2>&1 | sed '1d' | column -ts $'\t'
EOF
