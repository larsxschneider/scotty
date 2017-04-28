#!/usr/bin/env bash
#
# Print and count Git auth errors. Either all or per repo.
#
# Usage:
#   gitauth-errors.sh [OPTIONS] [<org>/<repo>]
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
#   gitauth-errors.sh -a -m foo/bar
#

BASE_DIR=$(cd "${0%/*}/.." && pwd)
. "$BASE_DIR/lib-ghe.sh"

# Default constants
INTERVAL=13 # --hour

while [ $# -gt 0 ]; do
    case $1 in
        (-m|--min)      INTERVAL=16; shift;;
        (-t|--tenmin)   INTERVAL=15; shift;;
        (--hour)        INTERVAL=13; shift;;
        (-d|--day)      INTERVAL=10; shift;;
        (--month)       INTERVAL=7; shift;;
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

execute << EOF
    zgrep -h -F -v 'status=OK' /var/log/github/gitauth.$LOG |
        $GREP_REPO |
        grep -F -v 'update_checksums' |
        grep -F -v 'DEBUG -- :' |
        grep -F -v 'INFO -- :' |
        grep -F -v 'method=refs_3pc' |
        grep -F -v '/usr/share/rbenv/versions/' |
        grep -F -v '/data/github/' |
        grep -F -v 'Deprecation warning: please give :encryption option as a Hash to Net::LDAP.new' |
        grep -F -v 'dumping backtrace' |
        grep -v '^==$' |
        grep -v '^$' |
        perl -lape 's/^.*now="(.{$INTERVAL}).* status=([^ ]*).*/\$1 \$2/' |
        perl -lape 's/^.*E, \[(.{$INTERVAL}).*\] ERROR -- :.*(timeout|reaped).*/\$1 \$2/' |
        sort |
        uniq -c |
        sort -k3 -k2
EOF
