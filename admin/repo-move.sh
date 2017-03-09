#!/usr/bin/env bash
#
# Move a repository to another organization.
#
# Usage:
#   repo-move.sh [OPTIONS] <source org/repo> <target org>
#
# Options:
#   --i-know-what-im-doing Suppress any warning (useful for scripting!)
#   -n                     Dry-run; only show what would be done.
#   -h, --help             Display this message.
#
# Example:
#   repo-move.sh org1/repo org2
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

SOURCE_SLUG=$1
if [ -z "$SOURCE_SLUG" ]; then
    usage "Source org/repo is a required parameter!"
fi

TARGET_ORG=$2
if [ -z "$TARGET_ORG" ]; then
    usage "Target org is a required parameter!"
fi

[ -n "$NO_WARNING" ] || warning "This script moves '$SOURCE_SLUG' to '$TARGET_ORG' on $GHE_HOST!"

execute << EOF
    github-env bin/runner -e production "'
        repo = Repository.nwo \"$SOURCE_SLUG\";
        target_org = User / \"$TARGET_ORG\";
        staff_user = User / \"$GHE_USER\";
        if repo and target_org and staff_user;
            repo.async_transfer_ownership_to(target_org, actor: staff_user, target_teams: []);
        else
            puts \"ERROR: Repo or target org does not exist.\";
        end;
    '"
EOF
