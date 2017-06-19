#!/usr/bin/env bash
#
# This script prints the number of request by type against GitHub Enterprise.
#
# Usage:
#   haproxy-requests.sh [OPTIONS]
#
# Options:
#   -m, --min     Aggregate by 1 minute
#   -t, --tenmin  Aggregate by 10 minute
#       --hour    Aggregate by 1 hour (default)
#   -d, --day     Aggregate by 1 day
#       --month   Aggregate by 1 month
#   -a, --all     Process all available logs (rolled logs)
#   -n            Dry-run; only show what would be done.
#   -h, --help    Display this message.
#
# Example:
#   haproxy-requests.sh -m
#

BASE_DIR=$(cd "${0%/*}/.." && pwd)
. "$BASE_DIR/lib-ghe.sh"

# Default constants
INTERVAL=9 # --hour

while [ $# -gt 0 ]; do
    case $1 in
        (-m|--min)      INTERVAL=12; shift;;
        (-t|--tenmin)   INTERVAL=11; shift;;
        (--hour)        INTERVAL=9; shift;;
        (-d|--day)      INTERVAL=6; shift;;
        (--month)       INTERVAL=3; shift;;
        (-a|--all)      all_logs; shift;;
        (-n)            DRY_RUN=1; shift;;
        (-h|--help)     usage 2>&1;;
        (--)            shift; break;;
        (-*)            usage "$1: unknown option";;
        (*) break;;
    esac
done

execute << EOF
    zcat -f /var/log/haproxy.$LOG |
        perl -lape 's/^(.{$INTERVAL}).*\] (https_protocol~ |git_protocol |http_protocol |ernicorn |ssh_protocol )?([^\d\/]*).*/\$1 \$3/' |
        sort |
        uniq -c
EOF
