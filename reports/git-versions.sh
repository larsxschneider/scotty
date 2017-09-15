#!/usr/bin/env bash
#
# Prints the recently used Git client versions per IP address or per user.
#
# Usage:
#   git-versions.sh
#
# Options:
#   -u, --user    Print results per user account (default: IP address)
#   -a, --all     Process all available logs (rolled logs
#   -n            Dry-run; only show what would be done.
#   -h, --help    Display this message.
#
# Example:
#   git-versions.sh
#

BASE_DIR=$(cd "${0%/*}/.." && pwd)
. "$BASE_DIR/lib-ghe.sh"

while [ $# -gt 0 ]; do
    case $1 in
        (-u|--user)     PER_USER=1; shift;;
        (-a|--all)      all_logs; shift;;
        (-h|--help)     usage 2>&1;;
        (-n)            DRY_RUN=1; shift;;
        (--)            shift; break;;
        (-*)            usage "$1: unknown option";;
        (*) break;;
    esac
done

if [ -z $PER_USER ]; then

    # We gather the Git agent via from two different sources here:
    #  - audit.log:   Currently, the audit log only reports the Git version
    #                 for "fetch" operations. Clients using the HTTPS and SSH
    #                 protocol are supported.
    #  - haproxy.log: This log reports the Git version for all kinds of
    #                 operations but only for clients that use the HTTPS
    #                 protocol.
    execute << EOF
        {
            zcat -f /var/log/github/audit.$LOG |
            perl -ne 'print if s/.*"real_ip":"([^"]*)".*agent=git\/(\d+(?:\.\d+){0,2}).*/\1 \2/' |
            sort |
            uniq &
            zcat -f /var/log/haproxy.$LOG |
            perl -ne 'print if s/.* (.*):.* \[.*\|\|git\/(\d+(?:\.\d+){0,2}).*/\1 \2/' |
            sort |
            uniq;
        } |
            sort |
            uniq |
            perl -lape 's/[^ ]+ //' |
            sort -r -V |
            uniq -c |
            awk '{printf("%s\t%s\n",\$2,\$1)}'
EOF
else
    execute << EOF
        zcat -f /var/log/github/audit.$LOG |
            perl -ne 'print if s/.*"real_ip":"([^"]*)".*"user_login":"([^"]*)".*agent=git\/(\d+(?:\.\d+){0,2}).*/\3 \2 \1/' |
            sort -r -V |
            uniq
EOF
fi
