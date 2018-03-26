#!/usr/bin/env bash
#
# Fork an external repo to your GitHub Enterprise instance, protect upstream
# branches against modifications, and set users with write permissions.
#
# Usage:
#   oss-fork.sh [OPTIONS] <repo-name> [<user-list> <source-repo-url>]
#
# Options:
#   -c, --create     Create a fork. You need to pass <user-list> <source-repo-url>.
#   -u, --update     Update a fork.
#   -a, --update-all Update all forks whose name contain the <repo-name>.
#   -n               Dry-run; only show what would be done.
#   -h, --help       Display this message.
#
# Example:
#   oss-fork.sh --create ossrepo usera,userb https://github.com/ossrepo/ossrepo.git
#   oss-fork.sh --update ossrepo
#
set -e

BASE_DIR=$(cd "${0%/*}/.." && pwd)
. "$BASE_DIR/lib-ghe.sh"

while [ $# -gt 0 ]; do
    case $1 in
        (-h|--help) usage 2>&1;;
        (-c|--create)     ACTION=create;     shift; break;;
        (-u|--update)     ACTION=update;     shift; break;;
        (-a|--update-all) ACTION=update-all; shift; break;;
        (--) shift; break;;
        (-*) usage "$1: unknown option";;
        (*) break;;
    esac
done

TARGET_REPO_NAME=$1
TARGET_REPO_COLLABORATORS=$2
SOURCE_URL=$3

[ -n "$TARGET_REPO_NAME" ] || error_exit "Repo name required!"

if [ "$ACTION" == "create" ]; then
    [ -n "$SOURCE_URL" ] || error_exit "Source URL required!"
    echo "Creating fork..."
    echo "Checking if $TARGET_REPO_NAME already exists ..."
    if ghe_api repos/$OSS_FORK_ORG/$TARGET_REPO_NAME > /dev/null; then
        echo "Target repo '$TARGET_REPO_NAME' already exist - updating."
        ghe_api \
            -X PATCH \
            --data '{
                "name":"'$TARGET_REPO_NAME'",
                "description":"Forked from '$SOURCE_URL'",
                "homepage":""
            }' \
            repos/$OSS_FORK_ORG/$TARGET_REPO_NAME > /dev/null
    else
        echo "Creating $TARGET_REPO_NAME ..."
        ghe_api \
            -X POST \
            --data '{
                "name":"'$TARGET_REPO_NAME'",
                "description":"Forked from '$SOURCE_URL'"
            }' \
            orgs/$OSS_FORK_ORG/repos > /dev/null
    fi
elif [ "$ACTION" == "update" ]; then
    SOURCE_URL=$(\
        ghe_api repos/$OSS_FORK_ORG/$TARGET_REPO_NAME |
        grep '"description": "Forked from' | grep -o '\(https\|http\|git\)://[^"]*' \
    )
    echo "Updating fork: $SOURCE_URL --> $TARGET_REPO_NAME"
elif [ "$ACTION" == "update-all" ]; then
    echo "Updating all repositories in '$OSS_FORK_ORG' whose name contain '$TARGET_REPO_NAME'..."

    # TODO: We only get up to 100 results here ... we might want to
    #       implement pagination properly at some point :-)
    REPOS=$(ghe_api "search/repositories?q=org%3A$OSS_FORK_ORG+$TARGET_REPO_NAME&type=Repositories&per_page=100" |
        perl -nE 'say /"name":\s*"([^"]+)/'
    )
    for REPO in $REPOS; do
        ${0} --update $REPO
    done
    exit 0
else
    echo "Unknown action '$ACTION'"
    exit 1
fi

echo "Cloning repo ..."
TARGET_REPO_URL=https://$GHE_HOST/$OSS_FORK_ORG/$TARGET_REPO_NAME
TEMP_REPO_PATH=$(mktemp -d)
pushd "$TEMP_REPO_PATH"
    git clone $SOURCE_URL .
    git remote set-url origin $TARGET_REPO_URL

    echo "Uploading and protecting upstream branches ..."
    for BRANCH in $(git for-each-ref --format='%(refname)' refs/remotes/origin/); do
        BRANCH_NAME=${BRANCH#refs/remotes/origin/}
        if [ "$BRANCH_NAME" != "HEAD" ]; then
            echo "Upload and protect: $BRANCH_NAME"
            git push -u origin $BRANCH:refs/heads/$BRANCH_NAME
            RETRY_COUNT=0
            until ghe_api \
                    -X PUT \
                    -H "Accept: application/vnd.github.luke-cage-preview+json" \
                    --data '{
                        "required_status_checks":null,
                        "restrictions": {
                            "users": ["'$OSS_FORK_UPDATE_USER'"], "teams": []
                        },
                        "enforce_admins":true,
                        "required_pull_request_reviews":null
                    }' \
                    repos/$OSS_FORK_ORG/$TARGET_REPO_NAME/branches/$BRANCH_NAME/protection \
                    > /dev/null || (( RETRY_COUNT++ >= 5 ))
            do
                echo "."
            done
        fi
    done

    echo "Uploading upstream tags ..."
    git push --tags

    DEFAULT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
    if [ "$ACTION" == "create" ]; then
        echo "Set default branch to $DEFAULT_BRANCH ..."
        set +e  # Might fail if the default branch is already correct
        ghe_api -X PATCH \
            --data '{ "name":"'$TARGET_REPO_NAME'" , "default_branch":"'$DEFAULT_BRANCH'" }' \
            repos/$OSS_FORK_ORG/$TARGET_REPO_NAME > /dev/null
        set -e
    fi
popd
rm -rf "$TEMP_REPO_PATH"

for USER in ${TARGET_REPO_COLLABORATORS//,/ }; do
    echo "Adding $USER as collaborator ..."
    ghe_api -X PUT \
        repos/$OSS_FORK_ORG/$TARGET_REPO_NAME/collaborators/${USER//_/-}?permission=push \
        > /dev/null
done

echo "Done: $TARGET_REPO_URL"
