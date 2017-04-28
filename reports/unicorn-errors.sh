#!/usr/bin/env bash
#
# Print and count unicorn errors.
#
# Usage:
#   unicorn-errors.sh [OPTIONS]
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
#   auunicornth-errors.sh -a
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

execute << EOF
    zcat -f /var/log/github/unicorn.$LOG |
        grep -v 'status=200' |
        grep -v 'status=201' |
        grep -v 'status=202' |
        grep -v 'status=204' |
        grep -v 'status=301' |
        grep -v 'status=302' |
        grep -v 'status=304' |
        grep -v 'status=307' |
        grep -v 'status=401' |
        grep -v 'status=403' |
        grep -v 'status=404' |
        grep -v '^would sync /data/user/storage' |
        grep -v 'at=issue.create' |
        grep -v 'INFO -- :' |
        grep -v 'DEBUG -- :' |
        grep -v 'graphql_success=true' |
        grep -v 'phase=ready_for_done' |
        grep -v -P '\t/data/github' |
        grep -v -P '\t/usr/share/rbenv/versions' |
        perl -lape 's/.*now="(.{$INTERVAL}).*status=([0-9]+).*/\$1 HTTP \$2/' |
        perl -lape 's/([\d-T ]{$INTERVAL}).*(DataQualityError).*/\$1 \$2/' |
        perl -lape 's/app=github.*(DataQualityError).*/NO-DATE \$1/' |
        perl -lape 's/(.{$INTERVAL}).*(initial_checksum gist-creation).*/\$1 \$2/' |
        perl -lape 's/(.{$INTERVAL}).*(update_checksums).*/\$1 \$2/' |
        perl -lape 's/(.{$INTERVAL}).*Errno::(.*)/\$1 \$2/' |
        perl -lape 's/(.{$INTERVAL}).*GitRPC::(.*)/\$1 \$2/' |
        perl -lape 's/.*\[(.{$INTERVAL}).*ERROR -- : ([^ ]+).*/\$1 \$2/' |
        perl -lape 's/.*at=([^ ]+).*class="([^"]+).*/NO-DATE \$1 \$2/' |
        perl -lape 's/.*(RollupSummary#save).*/NO-DATE \$1/' |
        perl -lape 's/.*graphql_query="([^ (]+).*/NO-DATE \$1/' |
        perl -lape 's/.*method=([^ ]+).*/NO-DATE \$1/' |
        perl -lape 's/.*message="([^"]+).*/NO-DATE \$1/' |
        perl -lape 's/.*warning: (.+)/NO-DATE \$1/' |
        perl -lape 's/(tree entry missing).*/NO-DATE \$1/' |
        sort |
        uniq -c
EOF
