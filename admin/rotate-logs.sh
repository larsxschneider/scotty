#!/usr/bin/env bash
#
# Rotate the GitHub logs
#
# Usage:
#   rotate-logs.sh
#
# Options:
#   -h, --help    Display this message.
#
# Example:
#   rotate-logs.sh
#

BASE_DIR=$(cd "${0%/*}/.." && pwd)
. "$BASE_DIR/lib-ghe.sh"

while [ $# -gt 0 ]; do
    case $1 in
        (-h|--help) usage 2>&1;;
        (--) shift; break;;
        (-*) usage "$1: unknown option";;
        (*) break;;
    esac
done

echo "Rotating the GitHub logs ..."
execute << EOF
    sudo logrotate -v -f /etc/logrotate.conf
EOF
