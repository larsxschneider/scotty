#!/usr/bin/env bash
#
# Promote a user as admin in an organization.
#
# Usage:
#   user-promote.sh [OPTIONS] <user> <org>
#
# Options:
#   -n            Dry-run; only show what would be done.
#   -h, --help    Display this message.
#
# Example:
#   user-promote.sh lars myorg
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

# GitHub usernames have a "-" instead of a "_"
USER=${1//_/-}
if [ -z "$USER" ]; then
    usage "User must not be empty."
fi

ORG=$2
if [ -z "$ORG" ]; then
    usage "Org must not be empty."
fi

echo "Promoting $USER to admin in $ORG..."
execute << EOF
    ghe-org-admin-promote -u $USER -o $ORD
EOF
