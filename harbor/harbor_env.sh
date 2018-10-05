#!/usr/bin/env bash
# @file harbor_env.sh
# Environment to test Docker Registry Harbor CLI
# @author Alister Lewis-Bowen <alister@lewis-bowen.org>

[[ -n $DEBUG ]] && set -x
set -eou pipefail

## Since each harbor CLI call needs to know the endpoint, credentials and
## (optionally but usefully) the project that we're working within, instead of
## using the options:
## -os-baseurl https://demo.goharbor.io --os-username admin --os-project 2
## we can alternatively set up the following environment vars 
export HARBOR_USERNAME=admin
export HARBOR_PASSWORD=Harbor12345
export HARBOR_URL=https://demo.goharbor.io
export HARBOR_PROJECT=2

# helper functions -----------------------------------------------------------

set_text_control_evars() {
    local colors=( BLACK RED GREEN YELLOW BLUE MAGENTA CYAN WHITE )
    for (( i=0; i<${#colors[@]}; i++ )); do
        export HBR_${colors[${i}]}="$(tput setaf ${i})"
        export HBR_B${colors[${i}]}="$(tput setab ${i})"
    done
    export HBR_BOLD="$(tput bold)"
    export HBR_DIM="$(tput dim)"
    export HBR_REV="$(tput rev)"
    export HBR_RESET="$(tput sgr0)"
}

export HBR_PREFIX='/usr/local/bin'

place_in_path() {
    [[ -e "$HBR_PREFIX/HBR_auth" ]] || {
        for file in $(find $PWD -name "HBR_*" | grep -Ev '.yml|.sample'); do
            ln -sf $file $HBR_PREFIX
        done
    }
}

heading() {
    echo
    printf "${HBR_DIM}=%.0s" {1..79}
    echo -e "\\n${1}" | fold -s -w 79
    printf -- "-%.0s${HBR_RESET}" {1..79}
    echo
    return 0
}

erun() {
    echo -e "${HBR_BOLD}〉${@} ${HBR_RESET}"
    "$@"
}

set_text_control_evars

## check the prerequisites are in place --------------------------------------

type harbor &> /dev/null || {
    heading 'Install Harbor CLI'
    echo "Install the Docker Registry Harbor CLI using pypi using"
    echo "sudo pip install python-harborclient" 
    exit 1
}

type harbor &> /dev/null || {
    heading 'Install docker CLI'
    echo "Install the Docker CLI using pypi using the instructions at"
    echo "https://docs.docker.com/docker-cloud/installing-cli/" 
    exit 1
}

## export HBR_NAME_PREFIX="alb-🦄"
export HBR_NAME_PREFIX="alb"
