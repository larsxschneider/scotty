#
# GHE Helper functions
#

# Default constants
LOG='log'
REQUIRED_GHE_MAJOR_VERSION='2.9'

function error_exit () {
    echo -e "\n$(tput setaf 1)###\n### ERROR\n###\n> $(tput sgr 0)$1\n" >&2
    echo -e "$(tput setaf 1)$ERROR_HELP_MESSAGE$(tput sgr 0)\n" >&2
    exit 1
}

function warning () {
    echo -e "\n$(tput setaf 3)###\n### WARNING\n###\n> $(tput sgr 0)$1\n" >&2
    [ -n "$DRY_RUN" ] || read -rsp $'Press any key to continue...\n' -n1 key
    echo -e "\n$(tput setaf 1)Processing...$(tput sgr 0)\n" >&2
}

function print_success () {
    echo -e "\n$(tput setaf 2)$1$(tput sgr 0)\n"
}

function usage() {
    [ "$*" ] && printf "$0: $*\n\n"
    sed -n '/^#/,/^$/ p' "$0" | cut -c 3- | tail -n +3
    exit 2
} 2>/dev/null

function all_logs() {
    LOG='log*'
}

function ghe_api() {
    API_PATH=${@: -1}

    PASSWORD=$(
        printf "protocol=https\nhost=$GHE_HOST\nusername=$GHE_USER\n\n" |
        git credential-$(git config credential.helper) get |
        perl -0pe 's/.*password=//s'
    )

    # TODO: We could have the user input the password with curl, too?
    [ -n "$PASSWORD" ] || error_exit "Credentials not found for '$GHE_HOST'. Did you setup a Git credential helper?"

    if [ -n "$DRY_RUN" ]; then
        echo "#"
        echo "# Dry run. The script would invoke the following API call on $GHE_HOST:"
        echo "#"
        echo
        echo "API Path:  $API_PATH"
        echo "Arguments: ${@:1:$(($#-1))}"
    else
        # TODO: Authentication works fine as we use tokens. Passwords with
        # special characters could become a problem here.
        curl --connect-timeout 5 --max-time 10 --retry 5 --retry-delay 0 \
             --retry-max-time 60 --silent --fail \
             --user "$GHE_USER:$PASSWORD" "${@:1:$(($#-1))}" \
             https://$GHE_HOST/api/v3/$API_PATH
    fi

}

function execute() {
    CHECK_VERSION="cat /etc/github/enterprise-release | \
        grep --quiet --fixed-strings 'RELEASE_VERSION=\"$REQUIRED_GHE_MAJOR_VERSION.' || \
        { echo 'ERROR: Refused to run script. Scotty was only tested with GHE $REQUIRED_GHE_MAJOR_VERSION!'; exit 1; }"
    if [ -n "$DRY_RUN" ]; then
        echo "#"
        echo "# Dry run. The script would invoke the following command on $GHE_HOST:"
        echo "#"
        echo
        echo $CHECK_VERSION
        cat
    else
        { echo $CHECK_VERSION; cat; } | ssh -i $GHE_KEY admin@$GHE_HOST -p 122 /bin/bash
    fi
}

if [ -e "$BASE_DIR/ghe.config" ]; then
    . "$BASE_DIR/ghe.config"
else
    error_exit "Please create a 'ghe.config' file (e.g. by copying 'ghe.config.template')."
fi
