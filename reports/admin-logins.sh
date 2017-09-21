#!/usr/bin/env bash
#
# Every key in ~/.ssh/authorized_keys has a comment section at the end
# which is usually used for email addresses. Print this comment section
# for every login to the administrative shell of GitHub Enterprise.
#
# Usage:
#   admin-logins.sh [OPTIONS]
#
# Options:
#   -a, --all     Process all available logs (rolled logs)
#   -n            Dry-run; only show what would be done.
#   -h, --help    Display this message.
#

BASE_DIR=$(cd "${0%/*}/.." && pwd)
. "$BASE_DIR/lib-ghe.sh"

while [ $# -gt 0 ]; do
    case $1 in
        (-a|--all)      all_logs; shift;;
        (-n) DRY_RUN=1; shift;;
        (-h|--help) usage 2>&1;;
        (--) shift; break;;
        (-*) usage "$1: unknown option";;
        (*) break;;
    esac
done

execute << EOF
    declare -A keys

    while read line; do
        [[ -n \$line ]] &&
        key=\$(ssh-keygen -l -f /dev/stdin <<<\$line | perl -nE 'print /\d+ ([^ ]+).+/') &&
        name=\$(printf "\$line" | perl -nE 'print /[^ ]+ [^ ]* (.+)/')
        [[ -n \$key ]] && keys[\$key]=\$name
    done < ~/.ssh/authorized_keys

    zgrep 'Accepted publickey for admin' /var/log/auth.$LOG |
        perl -nE 'say /.+ (.+)/' |
        while read key; do echo \${keys[\$key]}; done |
        sort |
        uniq -c |
        sort -n
EOF
