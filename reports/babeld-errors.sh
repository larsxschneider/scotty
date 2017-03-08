#!/usr/bin/env bash
#
# Print and count babeld errors. Either all or per repo.
#
# Usage:
#   auth-errors.sh [OPTIONS] [<org>/<repo>]
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
#   auth-errors.sh -a -m foo/bar
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

if [ -n "$1" ]; then
    GREP_REPO="grep -i -F $1"
else
    GREP_REPO="tee"
fi

ERR=(
    'account is suspended'
    'client write error'
    'denying auth for non-git user'
    'error flushing session'
    'error writing to git socket'
    'failed packfile write'
    'failed to peek pktline'
    'failed to verify pubkey'
    'Invalid username or password'
    'not a valid username or token'
    'op abruptly closed'
    'Permission'
    'pubkey probe failed'
    'pubkey signature validation WRONG'
    'pubkey with signature failed'
    'pump session exited with error'
    'Reading request body from client failed'
    'Repository not found'
    'server read error'
    'ssh_handle_key_exchange failed'
    'stats generation inc'
    'unhandled refupdate'
    'write failed git->ssh'

    # babeld is unable to authenticate an operation with a gitauth worker,
    # which we typically see when these workers are consumed with LDAP-based
    # polling.
    'unexpected return code from _gitauth'
)
IFS='|';ERR="${ERR[*]}";IFS=$' \t\n'

execute << EOF
    zcat -f /var/log/babeld/babeld.$LOG |
        $GREP_REPO |
        cut -c 5- |
        grep -F -v 'log_level=INFO' |
        perl -lape 's/^(.{$INTERVAL}).*msg="([^"]+).*/\$1 \$2/' |
        perl -lape 's/^(.{$INTERVAL}).*code=([0-9]+).*/\$1 HTTP \$2/' |
        perl -lape 's/^(.{$INTERVAL}).*($ERR).*/\$1 \$2/' |
        sort |
        uniq -c |
        sort -n |
        perl -lape 's/^(\s*\d+) (.{$INTERVAL})(.*)/\$2 | \$1\$3/' |
        sort
EOF
