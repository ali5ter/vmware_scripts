#!/usr/bin/env bash
# @file vke_env.sh
# Create an environment where these VKE scripts will work
# @author Alister Lewis-Bowen <alister@lewis-bowen.org>

[[ -n $DEBUG ]] && set -x
set -eou pipefail

source "vke_config.sh"

# helper functions -----------------------------------------------------------

export VKE_LATEST_CLI='/tmp/vke'

vke_cli_url() {
    local _urls
    _urls=$(curl -s https://api.vke.cloud.vmware.com/v1/cli)
    case "$OSTYPE" in
        darwin*)  jq -r .latest.urls.mac <<< "$_urls";; 
        linux*)   jq -r .latest.urls.linux64 <<< "$_urls";;
        msys*)    jq -r .latest.urls.windows64 <<< "$_urls";;
        *)        return 1;;
    esac
    return 0
}

vke_download_cli() {
    curl -s "$(vke_cli_url)" > $VKE_LATEST_CLI && chmod 755 $VKE_LATEST_CLI
    return 0
}

vke_cli_check_version() {
    local _latest_version
    local _current_version
    _latest_version=$($VKE_LATEST_CLI -v | sed 's/vke version \(.*\)/\1/')
    _current_version=$(vke -v | sed 's/vke version \(.*\)/\1/')
    [[ "$_current_version" != "$_latest_version" ]] && {
        heading 'New version of the VKE cli is available'
        echo "${VKE_BOLD}You currently have version $_current_version"
        echo "A new version ($_latest_version) is available${VKE_RESET}"
        echo "Move $VKE_LATEST_CLI to your path if you want the latest, e.g."
        echo -e " \\tmv $VKE_LATEST_CLI /usr/local/bin/vke\\n"
    }
    return 0
}

vke_cli_check_version_trigger() {
    local _check=~/.vke_version_check
    if [[ -f "$_check" ]]; then
        [[ "$(date '+%j')" != "$(cat $_check)" ]] && vke_cli_check_version
        date '+%j' > "$_check"
    else
        touch "$_check" && date '+%j' > "$_check"
        vke_cli_check_version
    fi
    return 0
}

set_text_control_evars() {
    local colors=( BLACK RED GREEN YELLOW BLUE MAGENTA CYAN WHITE )
    for (( i=0; i<${#colors[@]}; i++ )); do
        export VKE_${colors[${i}]}="$(tput setaf ${i})"
        export VKE_B${colors[${i}]}="$(tput setab ${i})"
    done
    export VKE_BOLD="$(tput bold)"
    export VKE_DIM="$(tput dim)"
    export VKE_REV="$(tput rev)"
    export VKE_RESET="$(tput sgr0)"
}

export VKE_PREFIX='/usr/local/bin'

place_in_path() {
    [[ -e "$VKE_PREFIX/vke_auth" ]] || {
        for file in $(find $PWD -name "vke_*" | grep -Ev '.yml|.sample'); do
            ln -sf "$file" $VKE_PREFIX
        done
    }
}

heading() {
    echo
    printf "${VKE_DIM}=%.0s" {1..79}
    echo -e "\\n${1}" | fold -s -w 79
    printf -- "-%.0s${VKE_RESET}" {1..79}
    echo
    return 0
}

erun() {
    echo -e "${VKE_BOLD}〉${@} ${VKE_RESET}"
    "$@"
}

vke_get_admin_for_object() {
    policy=$(vke -o json cluster iam show "$1")
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

type vke &> /dev/null || {
    heading 'Install VKE cli'
    echo "Downloading the VKE cli from the following URL:"
    vke_cli_url
    vke_download_cli
    echo "Move $VKE_LATEST_CLI to your path, e.g."
    echo -e " \\tmv $VKE_LATEST_CLI /usr/local/bin/vke\\n"
    echo "Once completed, you can restart this script."
    exit 1
}

[[ ! -f "$VKE_LATEST_CLI" ]] && vke_download_cli
vke_cli_check_version_trigger

type kubectl &> /dev/null || {
    heading 'kubectl required'
    echo 'Please install kubectl. Installation instructions are available from'
    echo 'https://kubernetes.io/docs/tasks/tools/install-kubectl/#install-kubectl-binary-via-curl'
    exit 1
}

## The API token can only be retrieved from the vke cli config...
export VKE_API_TOKEN="$(jq -r 'select(.Token)|.Token' ~/.vke-cli/vke-config)"

export VKE_SCRIPT_PATH="$( cd "$(dirname "$0")" ; pwd -P )"

export VKE_LOG="$PWD/vke_log.txt"

## Set up script references and global vars ----------------------------------

place_in_path
