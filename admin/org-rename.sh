#!/usr/bin/env bash
#
# Rename an organization.
#
# Usage:
#   org-rename.sh [OPTIONS] <old-name> <new-name>
#
# Options:
#   --i-know-what-im-doing Suppress any warning (useful for scripting!)
#   -n                     Dry-run; only show what would be done.
#   -h, --help             Display this message.
#
# Example:
#   org-rename.sh org1/repo org2
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

OLD_NAME=$1
if [ -z "$OLD_NAME" ]; then
    usage "Old org name is a required parameter!"
fi

NEW_NAME=$2
if [ -z "$NEW_NAME" ]; then
    usage "New org name is a required parameter!"
fi

execute << EOF
    github-env bin/runner -e production "'
        staff_user = User.find_by_login(\"$GHE_USER\");
        org = User.find_by_login(\"$OLD_NAME\");
        if org and staff_user;
            org.rename(\"$NEW_NAME\", actor: staff_user);
        else
            puts \"ERROR: Org or staff user does not exist.\";
        end;
    '"
EOF
