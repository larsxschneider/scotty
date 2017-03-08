#!/usr/bin/env bash
#
# Find hosts that create the most babeld errors.
#
# Usage:
#   babeld-errors-sources.sh [OPTIONS]
#
# Options:
#   -a, --all     Process all available logs (rolled logs)
#   -n            Dry-run; only show what would be done.
#   -h, --help    Display this message.
#
# Example:
#   babeld-errors-sources.sh
#

BASE_DIR=$(cd "${0%/*}/.." && pwd)
. "$BASE_DIR/lib-ghe.sh"

while [ $# -gt 0 ]; do
    case $1 in
        (-a|--all)      all_logs; shift;;
        (-n)            DRY_RUN=1; shift;;
        (-h|--help)     usage 2>&1;;
        (--)            shift; break;;
        (-*)            usage "$1: unknown option";;
        (*) break;;
    esac
done

execute << EOF
    zcat -f /var/log/babeld/babeld.$LOG |
        cut -c 5- |
        grep -F -v 'log_level=INFO' |
        grep -F 'ip=' |
        perl -lape 's/.*ip=([^ ]*).*/\$1/' |
        sort |
        uniq -c |
        sort -n |
        tail |
        while read -r LINE; do \
            IP=\$(echo "\$LINE" | awk '{ print \$2 }'); \
            TITLE=\$(curl --silent -L \$IP | grep -e '<title>.*</title>'); \
            echo "\$LINE \$TITLE"; \
        done
EOF
