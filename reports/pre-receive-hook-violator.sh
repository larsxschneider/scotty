#!/usr/bin/env bash
#
# Print the GitHub user names of pushers that violate a given
# pre-receive-hook.
#
# Usage:
#   pre-receive-hook-violator.sh [OPTIONS] [<pre-receive-hook>]
#
# Options:
#   -a, --all     Process all available logs (rolled logs
#   -n            Dry-run; only show what would be done.
#   -h, --help    Display this message.
#
# Example:
#   pre-receive-hook-violator.sh reject-external-email.sh
#

BASE_DIR=$(cd "${0%/*}/.." && pwd)
. "$BASE_DIR/lib-ghe.sh"

while [ $# -gt 0 ]; do
    case $1 in
        (-a|--all)      all_logs; shift;;
        (-h|--help)     usage 2>&1;;
        (-n)            DRY_RUN=1; shift;;
        (--)            shift; break;;
        (-*)            usage "$1: unknown option";;
        (*) break;;
    esac
done

HOOK_SCRIPT_NAME=$1
if [ -z "$HOOK_SCRIPT_NAME" ]; then
    usage "Hook script name must not be empty."
fi

execute << EOF
    zgrep -hF '${HOOK_SCRIPT_NAME}: failed with exit status' /var/log/github/audit.$LOG |
        perl -nE 'say /actor":"([^"]+)/' |
        sort -u
    printf "\nExecution timeouts: "
    zgrep -hF '${HOOK_SCRIPT_NAME}: execution exceeded' /var/log/github/audit.$LOG | wc -l
EOF
