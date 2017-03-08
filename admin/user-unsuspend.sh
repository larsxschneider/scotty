#!/usr/bin/env bash
#
# Unsuspend a user. It is not possible to unsuspend a user via the API
# if LDAP sync is enabled. Use this script instead!
#
# Usage:
#   user-unsuspend.sh [OPTIONS] <user> <GHE-path>
#
# Options:
#   -n            Dry-run; only show what would be done.
#   -h, --help    Display this message.
#
# Example:
#   user-unsuspend.sh lars
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

echo "Unsuspending $USER..."
execute << EOF
    ghe-user-unsuspend $USER
EOF
