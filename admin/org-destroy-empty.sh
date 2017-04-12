#!/usr/bin/env bash
#
# Destroy an empty organization.
#
# Usage:
#   org-destroy-empty.sh [OPTIONS] <org>
#
# Options:
#   --i-know-what-im-doing Suppress any warning (useful for scripting!)
#   -n                     Dry-run; only show what would be done.
#   -h, --help             Display this message.
#
# Example:
#   org-destroy-empty.sh myorg
#

BASE_DIR=$(cd "${0%/*}/.." && pwd)
. "$BASE_DIR/lib-ghe.sh"

while [ $# -gt 0 ]; do
    case $1 in
        (--i-know-what-im-doing) NO_WARNING=1; shift;;
        (-n) DRY_RUN=1; shift;;
        (-h|--help) usage 2>&1;;
        (--) shift; break;;
        (-*) usage "$1: unknown option";;
        (*) break;;
    esac
done

ORG=$1
if [ -z "$ORG" ]; then
    usage "Organization is a required parameter!"
fi

[ -n "$NO_WARNING" ] || warning "This script deletes '$ORG' from $GHE_HOST!"

execute << EOF
    github-env bin/runner -e production "'
        staff_user = User.find_by_login(\"$GHE_USER\");
        org = Organization.find_by_login(\"$ORG\");
        if staff_user and org and (org.repositories.count == 0);
            org.async_destroy(staff_user);
            org.update_attribute :gh_role, \"staff_delete\";
        else
            puts \"ERROR: User/org does not exist or org is not empty.\";
        end;
    '"
EOF
