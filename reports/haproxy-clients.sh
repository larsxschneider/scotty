#!/usr/bin/env bash
#
# This script prints the various HTTP clients that accessed GitHub Enterprise
# and counts the number of requests they made via HTTP(S) recently.
#
# Usage:
#   haproxy-clients.sh
#
# Options:
#   -a, --all     Process all available logs (rolled logs)
#   -h, --help    Display this message.
#
# Example:
#   haproxy-clients.sh
#

BASE_DIR=$(cd "${0%/*}/.." && pwd)
. "$BASE_DIR/lib-ghe.sh"

while [ $# -gt 0 ]; do
    case $1 in
        (-a|--all)      all_logs; shift;;
        (-h|--help)     usage 2>&1;;
        (--)            shift; break;;
        (-*)            usage "$1: unknown option";;
        (*) break;;
    esac
done

execute << EOF
    zgrep "https_protocol" /var/log/haproxy.$LOG |
        perl -nE 'say /(\{[^\}]+\})/' |
        perl -nE 'say /\|\|([^\}]+)/' | sort | uniq -c | sort -n -r
EOF
