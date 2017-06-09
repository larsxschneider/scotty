#!/usr/bin/env bash
#
# GHE will keep deleted repositories for 90 days. Use this script to
# purge the remains of a deleted repository immanently.
#
# Usage:
#   repo-purge-archived.sh [OPTIONS] <org> <repo>
#
# Options:
#   -n            Dry-run; only show what would be done.
#   -h, --help    Display this message.
#
# Example:
#   repo-purge-archived.sh foo bar
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
REPO=$2
if [ -z "$ORG" ] || [ -z "$REPO" ]; then
    usage "'Owner/Organization and repository must not be empty."
fi

execute << EOF
    github-env bin/runner -e production "'
        owner = User.find_by_login(\"$ORG\")
        if owner;
            repo = Archived::Repository.where(\"name = ? and owner_id = ?\", \"$REPO\", owner.id).first
            if repo;
                puts \"Purging archived repository with ID #{repo.id} (#{repo.name_with_owner})\"
                repo.purge
            else
                puts \"ERROR: Repository not found.\";
            end;
        else
            puts \"ERROR: Owner/Organization does not exist.\";
        end;
    '"
EOF
