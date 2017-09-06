#!/usr/bin/env bash
#
# Print GHE admin stats.
#
# See: https://developer.github.com/v3/enterprise/admin_stats/
#
# Usage:
#   admin-stats.sh [OPTIONS]
#
# Options:
#   -n            Dry-run; only show what would be done.
#   -h, --help    Display this message.
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

ghe_api enterprise/stats/all
