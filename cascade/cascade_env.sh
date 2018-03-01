#!/usr/bin/env bash
# @file cascade_env.sh
# Create an environment where these scripts will work
# @author Alister Lewis-Bowen <alister@lewis-bowen.org>

set -e

source "$PWD/cascade_config.sh"

# helper functions -----------------------------------------------------------

get_cli_url() {
    case "$OSTYPE" in
        darwin*)  echo 'https://s3-us-west-2.amazonaws.com/cascade-cli-download/pre-prod-us-west-2/latest/mac/cascade' ;; 
        linux*)   echo='https://s3-us-west-2.amazonaws.com/cascade-cli-download/pre-prod-us-west-2/latest/linux64/cascade' ;;
        msys*)    echo='https://s3-us-west-2.amazonaws.com/cascade-cli-download/pre-prod-us-west-2/latest/windows64/cascade.exe' ;;
        *)        return 1;;
    esac
    return 0
}

_heading_index=1

heading() {
    echo
    printf '=%.0s' {1..79}
    echo -e "\n$1" | fold -s -w 79
    printf -- '-%.0s' {1..79}
    echo
    return 0
}

_latest_cli='/tmp/cascade'

download_cli() {
    curl -s $(get_cli_url) > $_latest_cli && chmod 755 $_latest_cli
    return 0
}

check_version() {
    local _latest_version=$($_latest_cli -v | awk '{print $3}')
    local _current_version=$(cascade -v | awk '{print $3}')
    [[ "$_current_version" != "$_latest_version" ]] && {
        echo -e "\nThere is a new version ($_latest_version) of the Cascade CLI available"
        echo "Move $_latest_cli to your path if you want the latest, e.g."
        echo -e " \tmv $_latest_cli /usr/local/bin/cascade\n"
    }
    return 0
}

check_version_trigger() {
    local _check=~/.cascade_version_check
    if [[ -f "$_check" ]]; then
        [[ "$(date '+%j')" != "$(cat $_check)" ]] && check_version
        date '+%j' > "$_check"
    else
        touch "$_check" && date '+%j' > "$_check"
        check_version
    fi
    return 0
}

## check the prerequisites are in place --------------------------------------

[[ "$OSTYPE" == "darwin"* ]] && {
    _saved_ssid=~/.cascade_network_ssid
    touch "$_saved_ssid"
    SSID='vmware'
    _ifid=$(networksetup -listnetworkserviceorder | grep 'Hardware Port' | grep Wi-Fi | awk -F  "(, )|(: )|[)]" '{print $4}')
    _ssid=$(networksetup -getairportnetwork $_ifid | awk -F "(: )" '{print $2}')
    [[ "$_ssid" == "$SSID" || "$_ssid" == "$(cat $_saved_ssid)" ]] || {
        echo "You appear to be connected to $_ssid but need to connect to the wireless network at SSID, $SSID"
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
    echo 'Please install jq which is available from https://stedolan.github.io/jq/download/'
    exit 1
}

type cascade &> /dev/null || {
    echo "Downloading the Cascade CLI from the following URL:"
    get_cli_url
    download_cli
    echo "Move $_latest_cli to your path, e.g."
    echo -e " \tmv $_latest_cli /usr/local/bin/cascade\n"
    echo "Once completed, you can restart this script."
    exit 1
}

[[ ! -f "$_latest_cli" ]] && download_cli
check_version_trigger

source "$PWD/cascade_completion.sh"