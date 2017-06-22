#!/usr/bin/env bash
#
# Print and count GHE exceptions. Either all or per repo.
#
# Usage:
#   exceptions.sh [OPTIONS] [<org>/<repo>]
#
# Options:
#   -l, --latest  Print latest exceptions
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
#   exceptions.sh -a foo/bar
#

BASE_DIR=$(cd "${0%/*}/.." && pwd)
. "$BASE_DIR/lib-ghe.sh"

# Default constants
INTERVAL=13 # --hour

while [ $# -gt 0 ]; do
    case $1 in
        (-l|--latest)   LATEST=1; shift;;
        (-m|--min)      INTERVAL=16; shift;;
        (-t|--tenmin)   INTERVAL=15; shift;;
        (--hour)        INTERVAL=13; shift;;
        (-d|--day)      INTERVAL=10; shift;;
        (--month)       INTERVAL=7; shift;;
        (-a|--all) all_logs; shift;;
        (-n) DRY_RUN=1; shift;;
        (-h|--help) usage 2>&1;;
        (--) shift; break;;
        (-*) usage "$1: unknown option";;
        (*) break;;
    esac
done

if [ -n "$1" ]; then
    GREP_REPO="grep -i -F $1"
else
    GREP_REPO="tee"
fi

ERR=(
    '\(0\) from'
    'ajax'
    'anon_full'
    'ApplicationHelper::GitTemplateTimeout'
    'auto-corrected db repo checksum'
    'browser'
    'Cannot read property'
    'Cannot set property'
    'Connection reset by peer'
    'Connection timed out'
    'Couldn.t find'
    'Data Quality error trying to access #storage_blob'
    'ElasticsearchIllegalArgumentException'
    'expected to be at'
    'Failed to execute'
    'Internal Server Error'
    'LDAP operation error'
    'Network is unreachable'
    'no available servers'
    'No email found'
    'Not Found'
    'Orca::MysqlError'
    'read timeout reached'
    'Sketchy redirect URL'
    'undefined method'
)
IFS='|';ERR="${ERR[*]}";IFS=$' \t\n'

if [ -n "$LATEST" ]; then
    execute << EOF
        zcat -f /var/log/github/exceptions.$LOG |
            $GREP_REPO |
            jq 'del(.parsed_body, .body, .params, .threepc_state, .activerecord_objects, .backtrace, .cause, .delegate_replicas, .gitrpc_calls, .queries, .query_counts, .remote_backtrace, .request_timer_events)'
EOF
else
    execute << EOF
        zcat -f /var/log/github/exceptions.$LOG |
            $GREP_REPO |
            jq '.created_at + .message' |
            perl -lape 's/^"(.{$INTERVAL}).{$((27-$INTERVAL))}(.*)"$/\$1 \$2/' |
            perl -lape 's/^(.{$INTERVAL} )\[.+ sec\]\s*(.*)/\$1\$2/' |
            perl -lape 's/^(.{$INTERVAL} )(.*)\s*Real.+\(CPU.+Idle.+\)$/\$1\$2/' |
            perl -lape 's/^(.{$INTERVAL} )at (.*)\s*\(took.+idle\)$/\$1\$2/' |
            perl -lape 's/^(.{$INTERVAL} ).*application:github,category:([^,]*),route:([^,|\*]*).*/\$1\$2 \$2/' |
            perl -lape 's/^(.{$INTERVAL} ).*application:gitauth,category:(gitauth).*/\$1\$2/' |
            perl -lape 's/^(.{$INTERVAL} )(SELECT.*)\w*FROM.*/\$1\$2/' |
            perl -lape 's/^(.{$INTERVAL} )(UPDATE.*)\w*SET.*/\$1\$2/' |
            perl -lape 's/^(.{$INTERVAL} )(INSERT.*)\w*\(.*/\$1\$2/' |
            perl -lape 's/^(.{$INTERVAL} )(.*GET).*/\$1\$2/' |
            perl -lape 's/^(.{$INTERVAL} ).*($ERR).*/\$1\$2/' |
            sort |
            uniq -c |
            sort -k2 -k3
EOF
fi
