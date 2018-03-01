#!/usr/bin/env bash
# @file cascade_env.sh
# Create an environment where these scripts will work
# @author Alister Lewis-Bowen <alister@lewis-bowen.org>

set -e

source "$PWD/cascade_config.sh"

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
    echo "Please install cascade CLI by downloading it from"
    get_CLI_url
    echo "Add execute permissions and move into your path"
    exit 1
}

check_version_trigger

source "$PWD/cascade_completion.sh"