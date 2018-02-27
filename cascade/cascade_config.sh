#!/usr/bin/env bash
# @file cascade_config.sh
# Cascade account settings and common helper functions
# @author Alister Lewis-Bowen <alister@lewis-bowen.org>

UI_URL='https://cascade.cloud.vmware.com'
API_URL='https://api.cascade-cloud.com'
USER='bowena@vmware.com'
TOKEN='8698fa83-f29f-4354-aeb9-ac6c4a44bd1d'
CSP_ORG_ID='fa2c1d78-9f00-4e30-8268-4ab81862080d'

FOLDER_REGEX='ui'
PROJECT_REGEX='ui'
REGION_REGEX='us'
CLUSTER_PREFIX='alb'

# helper functions -----------------------------------------------------------

get_CLI_url() {
    local _os=''
    case "$OSTYPE" in
        darwin*)  _os='mac' ;; 
        linux*)   _os='linux64' ;;
        msys*)    _os='windows64' ;;
        *)        return 1;;
    esac
    curl -s "$UI_URL"/v1/cli | jq -r --arg os "$_os" '.latest | .[$os]'
    return 0
}

heading() {
    printf '=%.0s' {1..79}
    echo -e "\n$1" | fold -s -w 79
    printf '=%.0s' {1..79}
    echo
    return 0
}

check_version() {
    local _tmp='/tmp/cascade'
    local _latest_version=$(curl -s $(get_CLI_url) > $_tmp && chmod 755 $_tmp && $_tmp -v | awk '{print $3}')
    local _current_version=$(cascade -v | awk '{print $3}')
    [[ "$_current_version" != "$_latest_version" ]] && {
        echo -e "\nThere is a new version ($_latest_version) of the Cascade CLI available"
        echo "Move $_tmp to your path if you want the latest, e.g."
        echo -e " \tmv $_tmp /usr/local/bin/cascade\n"
    }
    return 0
}

check_version_trigger() {
    local _check=~/.cascade_version_check
    if [[ -f "$_check" ]]; then
        [[ "$(date '+%j')" != "$(cat $_check)" ]] && check_version
    else
        touch "$_check" && { date '+%j' > "$_check"; }
        check_version
    fi
    return 0
}

# validate cascade commands ---------------------------------------------------

type jq &> /dev/null || {
    echo 'Please install jq which is available from https://stedolan.github.io/jq/download/'
    exit 1
}

type cascade &> /dev/null || {
    echo "Please install cascade CLI by downloading it from"
    get_CLI_url
    echo "Add execute permissions and move into your path"
    exit 1
}

check_version_trigger

source "$PWD/cascade_completion.sh"