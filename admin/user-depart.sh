#!/usr/bin/env bash
#
# Remove a user from all organizations
#
# Usage:
#   user-depart.sh [OPTIONS] <user>
#
# Options:
#   -n            Dry-run; only show what would be done.
#   -h, --help    Display this message.
#
# Example:
#   user-depart.sh lars
#

BASE_DIR=$(cd "${0%/*}/.." && pwd)
. "$BASE_DIR/lib-ghe.sh"

while [ $# -gt 0 ]; do
    case $1 in
        (-n) DRY_RUN=1; shift;;
        (-h|--help) usage 2>&1;;
        (--) shift; break;;
        (-*) usage "$1: unknown option";;
        (*) break;;
    esac
done

# GitHub usernames have a "-" instead of a "_"
USER=${1//_/-}
if [ -z "$USER" ]; then
    usage "User must not be empty."
fi

echo "Removing $USER from all organizations ..."
execute << EOF
    github-env bin/runner -e production "'
        user = User.find_by_login(\"$USER\");
        if user.nil?;
            puts \"$USER does not exist.\"
            exit
        end;
        user.organizations.each do |organization|;
            organization.remove_member(user, send_notification: false);
            puts \"Removed #{user.login} from #{organization.name}\";
        end;
    '"
EOF
