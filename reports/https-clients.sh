#!/usr/bin/env bash
#
# This script aggregates and reports the various clients 
# that make requests via HTTP(S) recently.
#
# Usage:
#   https-clients.sh
#
# Options:
#   -h, --help    Display this message.
#
# Example:
#   https-clients.sh
#

BASE_DIR=$(cd "${0%/*}/.." && pwd)
. "$BASE_DIR/lib-ghe.sh"

while [ $# -gt 0 ]; do
    case $1 in
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
