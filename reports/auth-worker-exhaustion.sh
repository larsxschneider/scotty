#!/usr/bin/env bash
#
# If requests are authenticated with LDAP username and password then GitHub
# Enterprise might not be able to check these credentials because of GitAuth
# worker exhaustion. This script prints the users that might be affected.
#
# Please note:
#  - The usernames displayed are what the users provided. That means they
#    might not be correct or might not exist.
#  - Another indicator for auth worker exhaustion is that a babeld.log entry
#    does not have a corresponding gitauth.log entry. This is not checked here.
#
# A remediation strategy is to use a SSH key or an Oauth token for
# authentication.
#
# c.f. https://support.enterprise.github.com/hc/en-us/requests/47506
#
# Usage:
#   auth-worker-exhaustion.sh
#
# Options:
#   -a, --all     Process all available logs (rolled logs)
#   -n            Dry-run; only show what would be done.
#   -h, --help    Display this message.
#
# Example:
#   auth-worker-exhaustion.sh
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
    zgrep -hF 'user=' /var/log/babeld/babeld.$LOG |
        grep 'duration_ms=3....\....... ' |                     # babeld has a GitAuth connect timeout of 10 sec, and tries three times (== 30 seconds).
        grep 'total_fs_connect_time_ms=0.000000' |              # indicates that babeld hasn't moved past the authentication phase
        perl -lape 's/.* user=(?:user:\d+:)?([^" ]+).*/\$1/' |  # only look at users and ignore deploy keys (identified by "repo:123:somerepo" user names)
        sort |
        uniq
EOF
