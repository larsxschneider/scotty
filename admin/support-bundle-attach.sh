#!/usr/bin/env bash
#
# Attach files to a GitHub Enterprise support ticket.
#
# Usage:
#   support-bundle-attach.sh [OPTIONS] <GHE-ticket-id> <GHE-path>
#
# Options:
#   -n            Dry-run; only show what would be done.
#   -h, --help    Display this message.
#
# Example:
#   support-bundle-attach.sh 123 '/var/log/chrony/*'
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
DATA=$2

if [ -z "$TICKET" ]; then
    usage "GHE-ticket-id must not be empty."
fi
echo "Ticket ID: $TICKET"

if [ -z "$DATA" ]; then
    usage "GHE-path must not be empty."
fi
echo "Path:      $DATA"

execute << EOF
    tar -zcvf ~/logs-$TICKET.tgz $DATA
    ghe-support-bundle -f ~/logs-$TICKET.tgz -t $TICKET
    rm ~/logs-$TICKET.tgz
EOF
