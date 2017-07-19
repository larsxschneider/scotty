#!/usr/bin/env bash
#
# Attach files to a GitHub Enterprise support ticket from your local machine.
#
# Usage:
#   support-bundle-local-attach.sh [OPTIONS] <GHE-ticket-id> <path-to-file>
#
# Options:
#   -h, --help    Display this message.
#
# Example:
#   support-bundle-local-attach.sh 123 '/path/to/some/file'
#

BASE_DIR=$(cd "${0%/*}/.." && pwd)
. "$BASE_DIR/lib-ghe.sh"

while [ $# -gt 0 ]; do
    case $1 in
        (-h|--help) usage 2>&1;;
        (--) shift; break;;
        (-*) usage "$1: unknown option";;
        (*) break;;
    esac
done

TICKET=$1
FILE_PATH=$2

if [ -z "$TICKET" ]; then
    usage "GHE-ticket-id must not be empty."
fi
echo "Ticket ID: $TICKET"

if ! [ -f "$FILE_PATH" ]; then
    usage "The local file path must not be empty."
fi
echo "Path:      $FILE_PATH"

TOKEN=$(
    curl \
        -X POST \
        -d "bundle[uploaded_by]=uploader@enterprise.github.com" \
        https://enterprise-bundles.github.com/bundles/token.json 2>/dev/null |
    sed 's,^.*:"\(.*\)".*$,\1,'
)
curl \
    -X POST \
    -F "token=$TOKEN" \
    -F "bundle[ticket_id]=$TICKET" \
    -F "bundle[file]=@${FILE_PATH}" -# \
    https://enterprise-bundles.github.com/bundles.json >/dev/null

echo "Done!"
