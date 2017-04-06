#!/usr/bin/env bash
#
# Restart the management console
#
# Usage:
#   restart-management-console.sh
#
# Options:
#   -h, --help    Display this message.
#
# Example:
#   restart-management-console.sh
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

execute << EOF
    sudo service enterprise-manage stop
    sleep 10
    sudo service enterprise-manage start
EOF
