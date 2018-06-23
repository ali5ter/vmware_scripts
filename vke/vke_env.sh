#!/usr/bin/env bash
# @file vke_env.sh
# Create an environment where these VKE scripts will work
# @author Alister Lewis-Bowen <alister@lewis-bowen.org>

[[ -n $DEBUG ]] && set -x
# set -euf -o pipefail ## ref: https://sipb.mit.edu/doc/safe-shell/
set -eou pipefail

source "$PWD/vke_config.sh"

# helper functions -----------------------------------------------------------

get_cli_url() {
    case "$OSTYPE" in
        ## Pulled from `curl https://api.vke.cloud.vmware.com/v1/cli | jq .latest``
        darwin*)  echo 'https://s3-us-west-2.amazonaws.com/cascade-cli-download/pre-prod-us-west-2/latest/mac/vke' ;; 
        linux*)   echo='https://s3-us-west-2.amazonaws.com/cascade-cli-download/pre-prod-us-west-2/latest/linux64/vke' ;;
        msys*)    echo='https://s3-us-west-2.amazonaws.com/cascade-cli-download/pre-prod-us-west-2/latest/windows64/vke.exe' ;;
        *)        return 1;;
    esac
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

place_in_path() {
    for file in $(find $PWD -name "vke_*" | grep -Ev '.yml|.sh'); do
        ln -sf $file /usr/local/bin/
    done
}

heading() {
    echo
    printf "${VKE_DIM}=%.0s" {1..79}
    echo -e "\n${1}" | fold -s -w 79
    printf -- "-%.0s${VKE_RESET}" {1..79}
    echo
    return 0
}

VKE_LATEST_CLI='/tmp/vke'

download_cli() {
    curl -s $(get_cli_url) > $VKE_LATEST_CLI && chmod 755 $VKE_LATEST_CLI
    return 0
}

check_version() {
    local _latest_version=$($VKE_LATEST_CLI -v | sed 's/vke version \(.*\)/\1/')
    local _current_version=$(vke -v | sed 's/vke version \(.*\)/\1/')
    [[ "$_current_version" != "$_latest_version" ]] && {
        heading 'New version of the VKE cli is available'
        echo "${VKE_BOLD}You currently have version $_current_version"
        echo "A new version ($_latest_version) is available${VKE_RESET}"
        echo "Move $VKE_LATEST_CLI to your path if you want the latest, e.g."
        echo -e " \tmv $VKE_LATEST_CLI /usr/local/bin/vke\n"
    }
    return 0
}

check_version_trigger() {
    local _check=~/.vke_version_check
    if [[ -f "$_check" ]]; then
        [[ "$(date '+%j')" != "$(cat $_check)" ]] && check_version
        date '+%j' > "$_check"
    else
        touch "$_check" && date '+%j' > "$_check"
        check_version
    fi
    return 0
}


erun() {
    echo -e "${VKE_BOLD}〉${@} ${VKE_RESET}"
    "$@"
}

get_admin() {
    local obj="$1"
    local policy=$(vke -o json cluster iam show $1)
    local direct=$(echo $policy | jq -r '.direct.bindings[]')
    local inherited=$(echo $policy | jq -r '.inherited[].bindings[]')

    local admin=$(echo $direct | jq -r 'select(.role == "smartcluster.admin") | .subjects[]')
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

[[ "$OSTYPE" == "darwin"* ]] && {
    _saved_ssid=~/.vke_network_ssid
    touch "$_saved_ssid"
    SSID='vmware'
    _ifid=$(networksetup -listnetworkserviceorder | grep 'Hardware Port' | grep Wi-Fi | awk -F  "(, )|(: )|[)]" '{print $4}')
    _ssid=$(networksetup -getairportnetwork $_ifid | awk -F "(: )" '{print $2}')
    [[ "$_ssid" == "$SSID" || "$_ssid" == "$(cat $_saved_ssid)" ]] || {
        heading 'Network access confirmation'
        echo "You appear to be connected to ${VKE_BOLD}${_ssid}${VKE_RESET}."
        echo "However, you need to connect to the wireless network at SSID, ${VKE_BOLD}${SSID}${VKE_RESET}"
        read -p "Or are you connected through VPN? [y/N] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "$_ssid" > "$_saved_ssid"
        else
            exit 1
        fi
    }
}

type jq &> /dev/null || {
    heading 'jq required'
    echo 'Please install jq which is available from https://stedolan.github.io/jq/download/'
    exit 1
}

type vke &> /dev/null || {
    heading 'Install VKE cli'
    echo "Downloading the VKE cli from the following URL:"
    get_cli_url
    download_cli
    echo "Move $VKE_LATEST_CLI to your path, e.g."
    echo -e " \tmv $VKE_LATEST_CLI /usr/local/bin/vke\n"
    echo "Once completed, you can restart this script."
    exit 1
}

[[ ! -f "$VKE_LATEST_CLI" ]] && download_cli
check_version_trigger

## TODO: Write this to a runcom like .bashrc
source "$PWD/vke_bash_completion.sh"

type kubectl &> /dev/null || {
    heading 'kubectl required'
    echo 'Please install kubectl. Installation instructions are available from'
    echo 'https://kubernetes.io/docs/tasks/tools/install-kubectl/#install-kubectl-binary-via-curl'
    exit 1
}

## Set up script references and global vars ----------------------------------

place_in_path

## The API token can only be retrieved from the vke cli config...
VKE_API_TOKEN="$(jq -r .Token ~/.vke-cli/vke-config)"

VKE_SCRIPT_PATH="$( cd "$(dirname "$0")" ; pwd -P )"