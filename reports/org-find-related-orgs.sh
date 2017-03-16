#!/usr/bin/env bash
#
# Find orgs related to a given org via common admins.
#
# Usage:
#   org-find-related-orgs.sh [OPTIONS] <org>
#
# Options:
#   -n                     Dry-run; only show what would be done.
#   -h, --help             Display this message.
#
# Example:
#   org-find-related-orgs.sh testorg
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

ORG=$1
if [ -z "$ORG" ]; then
    usage "Org must not be empty."
fi

# Hint:
# You can filter service accounts/bot users like this
#     members=(User / \"$ORG\").members.reject {
#                 |u| u.login == \"bot-user\" or
#                     u.login.start_with?(\"service-\")
#             };

execute << EOF
    github-env bin/runner -e production "'
        members=(User / \"$ORG\").members;
        Organization.find_each do |org|
            admins = (org.admins & members).map { |u| u.login }.sort;
            if !(admins).empty?;
                puts \"#{org.name} #{admins}\";
            end;
        end
    '"
EOF
