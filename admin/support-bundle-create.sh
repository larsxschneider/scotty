#!/usr/bin/env bash
#
# Create a support bundle and attach it to a ticket.
#
# Usage:
#   support-bundle-create.sh [OPTIONS] <GHE-ticket-id>
#
# Options:
#   -n            Dry-run; only show what would be done.
#   -h, --help    Display this message.
#
# Example:
#   support-bundle-create.sh 123
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

TICKET=$1

if [ -z "$TICKET" ]; then
    usage "GHE-ticket-id must not be empty."
fi
echo "Ticket ID: $TICKET"

execute << EOF
    nohup ghe-support-bundle -t $TICKET &
EOF
