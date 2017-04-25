#!/usr/bin/env bash
#
# Print admins of an org. The GH API allows to query the admins, too,
# but you would need to be an admin in that org yourself to see
# non-public members.
#
# c.f. https://developer.github.com/v3/orgs/members/
#
# Usage:
#   org-admins.sh [OPTIONS] <org>
#
# Options:
#   -e, --email            Print email addresses instead of usernames.
#   -n                     Dry-run; only show what would be done.
#   -h, --help             Display this message.
#
# Example:
#   org-admins.sh testorg
#

BASE_DIR=$(cd "${0%/*}/.." && pwd)
. "$BASE_DIR/lib-ghe.sh"

PROPERTY="login"
SEPARATOR="\\n"
while [ $# -gt 0 ]; do
    case $1 in
        (-e|--email) PROPERTY="email"; SEPARATOR="; "; shift;;
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
    github-env bin/runner -e production "'
        admins=(User / \"$ORG\").admins.select { |u| not u.disabled and not u.suspended_at }.map { |u| u.$PROPERTY }.sort;
        puts admins.join(\"$SEPARATOR\");
    '"
EOF
