#!/usr/bin/env bash
#
# Remove a string from all history of a repository.
#
# Usage:
#   repo-remove-sensitive-string.sh [OPTIONS] <org>/<repo> <secret>
#
# Options:
#   -h, --help    Display this message.
#
# Example:
#   repo-remove-sensitive-string.sh foo/bar 'SECRET'
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

REPO=$1
if [ -z "$REPO" ]; then
    usage "'Org/Repo' must not be empty."
fi

STRING=$2
if [ -z "$STRING" ]; then
    usage "'String' must not be empty."
fi

TEMP_REPO_PATH=$(mktemp -d)
pushd "$TEMP_REPO_PATH"
    git clone https://$GHE_HOST/$REPO .

    # TODO: Works only on OSX for now
    git filter-branch --tree-filter \
        "LANG=C LC_CTYPE=C find . -type f -exec sed -i '' 's/$STRING/REMOVED/g' '{}' \;" -- --all

    git push --tags --force

    # Overwrite all branches. origin contains a HEAD ref that we need to
    # delete afterwards. Would be nice to have a more elegant solution!
    git push origin +refs/remotes/origin/\*:refs/heads/\*
    git push -d origin HEAD
popd
rm -rf "$TEMP_REPO_PATH"

warning "Please run 'repo-prune-orphaned-objects.sh $REPO' and tell everyone to re-clone the repo!"
