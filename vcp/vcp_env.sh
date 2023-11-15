#!/usr/bin/env bash
# @file vcp_env.sh
# Create an environment where these VCP scripts will work
# @author Alister Lewis-Bowen <alister@lewis-bowen.org>

[[ -n $DEBUG ]] && set -x
set -eou pipefail

# shellcheck disable=SC1091
source "vcp_config.sh"

# helper functions -----------------------------------------------------------

export VCP_LATEST_CLI='/tmp/vcp'

vcp_cli_url() {
    case "$OSTYPE" in
        ## Pulled from `curl https://api.vcp.cloud.vmware.com/v1/cli | jq .latest``
        darwin*)  echo 'https://s3-us-west-2.amazonaws.com/cascade-cli-download/pre-prod-us-west-2/latest/mac/vcp' ;; 
        linux*)   echo 'https://s3-us-west-2.amazonaws.com/cascade-cli-download/pre-prod-us-west-2/latest/linux64/vcp' ;;
        msys*)    echo 'https://s3-us-west-2.amazonaws.com/cascade-cli-download/pre-prod-us-west-2/latest/windows64/vcp.exe' ;;
        *)        return 1;;
    esac
    return 0
}

vcp_download_cli() {
    curl -s "$(vcp_cli_url)" > $VCP_LATEST_CLI && chmod 755 $VCP_LATEST_CLI
    return 0
}

vcp_cli_check_version() {
    local _latest_version
    local _current_version
    _latest_version=$($VCP_LATEST_CLI -v | sed 's/vcp version \(.*\)/\1/')
    _current_version=$(vcp -v | sed 's/vcp version \(.*\)/\1/')
    [[ "$_current_version" != "$_latest_version" ]] && {
        heading 'New version of the VKE cli is available'
        echo "${VCP_BOLD}You currently have version $_current_version"
        echo "A new version ($_latest_version) is available${VCP_RESET}"
        echo "Move $VCP_LATEST_CLI to your path if you want the latest, e.g."
        echo -e " \\tmv $VCP_LATEST_CLI /usr/local/bin/vcp\\n"
    }
    return 0
}

vcp_cli_check_version_trigger() {
    local _check=~/.vcp_version_check
    if [[ -f "$_check" ]]; then
        [[ "$(date '+%j')" != "$(cat $_check)" ]] && vcp_cli_check_version
        date '+%j' > "$_check"
    else
        touch "$_check" && date '+%j' > "$_check"
        vcp_cli_check_version
    fi
    return 0
}

set_text_control_evars() {
    local colors=( BLACK RED GREEN YELLOW BLUE MAGENTA CYAN WHITE )
    for (( i=0; i<${#colors[@]}; i++ )); do
        export "VCP_${colors[${i}]}=$(tput setaf ${i})"
        export "VCP_B${colors[${i}]}=$(tput setab ${i})"
    done
    # shellcheck disable=SC2155
    export VCP_BOLD="$(tput bold)"
    # shellcheck disable=SC2155
    export VCP_DIM="$(tput dim)"
    # shellcheck disable=SC2155
    export VCP_REV="$(tput rev)"
    # shellcheck disable=SC2155
    export VCP_RESET="$(tput sgr0)"
}

export VCP_PREFIX='/usr/local/bin'

place_in_path() {
    [[ -e "$VCP_PREFIX/vcp_auth" ]] || {
        for file in $(find "$PWD" -name "vcp_*" | grep -Ev '.yml|.sample'); do
            ln -sf "$file" $VCP_PREFIX
        done
    }
}

heading() {
    echo
    printf "${VCP_DIM}=%.0s" {1..79}
    echo -e "\\n${1}" | fold -s -w 79
    printf -- "-%.0s${VCP_RESET}" {1..79}
    echo
    return 0
}

erun() {
    # shellcheck disable=SC2145
    echo -e "${VCP_BOLD}〉${@} ${VCP_RESET}"
    "$@"
}

vcp_get_admin_for_object() {
    policy=$(vcp -o json cluster iam show "$1")
    direct=$(echo $policy | jq -r '.direct.bindings[]')
    inherited=$(echo $policy | jq -r '.inherited[].bindings[]')

    admin=$(echo $direct | jq -r 'select(.role == "smartcluster.admin") | .subjects[]')
    if [[ -z "$admin" ]]; then
        admin=$(echo $inherited | jq -r 'select(.role == "smartcluster.admin") | .subjects[]')
        if [[ -z "$admin" ]]; then
            admin=$(echo $inherited | jq -r 'select(.role == "project.admin") | .subjects[]')
            if [[ -z "$admin" ]]; then 
                admin=$(echo $inherited | jq -r 'select(.role == "folder.admin") | .subjects[]')
                if [[ -z "$admin" ]]; then
                    admin=$(echo $inherited | jq -r 'select(.role == "tenant.admin") | .subjects[]')
                fi
            fi
        fi
    fi
    echo "$admin"
}

set_text_control_evars

## check the prerequisites are in place --------------------------------------

type jq &> /dev/null || {
    heading 'jq required'
    echo 'Please install jq which is available from https://stedolan.github.io/jq/download/'
    exit 1
}

type vcp &> /dev/null || {
    heading 'Install VKE cli'
    echo "Downloading the VKE cli from the following URL:"
    vcp_cli_url
    vcp_download_cli
    echo "Move $VCP_LATEST_CLI to your path, e.g."
    echo -e "\\tmv $VCP_LATEST_CLI /usr/local/bin/vcp\\n"
    echo "Once completed, you can restart this script."
    exit 1
}

[[ ! -f "$VCP_LATEST_CLI" ]] && vcp_download_cli
vcp_cli_check_version_trigger

type kubectl &> /dev/null || {
    heading 'kubectl required'
    echo 'Please install kubectl. Installation instructions are available from'
    echo 'https://kubernetes.io/docs/tasks/tools/install-kubectl/#install-kubectl-binary-via-curl'
    exit 1
}

## The API token can only be retrieved from the vcp cli config...
# shellcheck disable=SC2155
export VCP_API_TOKEN="$(jq -r .Token ~/.vcp-cli/vcp-config)"
# shellcheck disable=SC2155
export VCP_SCRIPT_PATH="$( cd "$(dirname "$0")" ; pwd -P )"
# shellcheck disable=SC2155
export VCP_LOG="$PWD/vcp_log.txt"

## Set up script references and global vars ----------------------------------

place_in_path
