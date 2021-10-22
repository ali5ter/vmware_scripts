#!/usr/bin/env bash
# @file tmc_env.sh
# Create an environment where these tmc scripts can work
# @author Alister Lewis-Bowen <alister@lewis-bowen.org>

[[ -n $DEBUG ]] && set -x
set -eou pipefail

# shellcheck disable=SC1091
source tmc_config.sh

# helper functions -----------------------------------------------------------

set_text_control_evars() {
    local colors=( BLACK RED GREEN YELLOW BLUE MAGENTA CYAN WHITE )
    for (( i=0; i<${#colors[@]}; i++ )); do
        # shellcheck disable=SC2086
        export TMC_${colors[${i}]}="$(tput setaf ${i})"
        # shellcheck disable=SC2086
        export TMC_B${colors[${i}]}="$(tput setab ${i})"
    done
    # shellcheck disable=SC2155
    export TMC_BOLD="$(tput bold)"
    # shellcheck disable=SC2155
    export TMC_DIM="$(tput dim)"
    # shellcheck disable=SC2155
    export TMC_REV="$(tput rev)"
    # shellcheck disable=SC2155
    export TMC_RESET="$(tput sgr0)"
}
set_text_control_evars

heading() {
    echo
    printf "${TMC_DIM}=%.0s" {1..79}
    echo -e "\\n${1}" | fold -s -w 79
    printf -- "-%.0s${TMC_RESET}" {1..79}
    echo
}

function set_up() {
    heading "Create TMC context to authenticate with TMC service"

    for cmd in tmc kubectl jq; do
        command -v "$cmd" 1>/dev/null 2>&1 || {
            echo "🙄 Unable to find $cmd."
        exit 1
        }
    done

    # Create fresh context
    tmc system context list | grep "$TMC_CONTEXT" >/dev/null && \
        tmc system context delete "$TMC_CONTEXT" >/dev/null
    export TMC_API_TOKEN="$TMC_API_TOKEN"
    tmc login --stg-unstable --name "$TMC_CONTEXT" --no-configure

    # !! Can't list defaults. Have to look in current context
    # !! but even then, loglevel value is different
    tmc configure -m "$TMC_MNGMT_CLUSTER" -p "$TMC_PROVISIONER" -l "$TMC_LOG_LEVEL"
    # tmc configure -m attached -p attached -l "$TMC_LOG_LEVEL"
    tmc cluster list 1>/dev/null 2>/dev/null || {
        echo "😱 Looks like the connnection filed while performing a CLI update."
        exit 1
    }
    tmc system context list
    echo
}

function context_detail() {
    heading "Context detail"
    tmc system context current -o json > context.json
    echo -e "Organization ID:\\t$(jq -r .spec.orgId context.json)"
    echo -e "Endpoint:\\t$(jq -r .spec.endpoint context.json)"
    echo -e "Username:\\t$(jq -r .status.userName context.json)"
    echo -e "Org perms:\\t$(jq -r .status.permissions context.json)"
    echo "Defaults:"
    echo -e "Management cluster: \\t$(jq -r .spec.env.MANAGEMENT_CLUSTER_NAME context.json)"
    echo -e "Provisioner: \\t$(jq -r .spec.env.PROVISIONER_NAME context.json)"
    rm context.json
}

function start_local_cluster() {
    heading "Make sure a local k8s cluster exists"
    # shellcheck disable=SC2155
    local cname="$(kind get clusters -q)"
    # shellcheck disable=SC2153
    if [ "$cname" == "$TMC_CLUSTER_NAME" ]; then
        read -p "✋ Looks like a kind cluster, $cname, exists. Want me to delete this one? [y/N] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            kind delete cluster --name="$cname" && \
            kind create cluster --config kind_config.yaml --name="$TMC_CLUSTER_NAME"
        fi 
    else 
        kind create cluster --config kind_config.yaml --name="$TMC_CLUSTER_NAME"
    fi
    echo
}

function clean_up() {
    heading "Clean up cluster resources"

    # TODO: Check cluster still attached
    read -p "✋ Do you want me to detach $TMC_CLUSTER_NAME? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        tmc cluster delete "$TMC_CLUSTER_NAME" -m attached -p attached \
            --force
        # Inspect cluster health
        # !! output flag not documented
        echo "Checking cluster $TMC_CLUSTER_NAME has detached"
        # shellcheck disable=SC2086
        while [ "$(tmc cluster get $TMC_CLUSTER_NAME \
                -m attached -p attached \
                -o json | jq -r .status.phase)" == 'DETACHING' ]; do
            echo -n '.'
            sleep 10
        done
        echo ' ✅'
    fi

    read -p "✋ Do you want me to delete the kind cluster, $TMC_CLUSTER_NAME? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        kind delete cluster --name="$TMC_CLUSTER_NAME"
    fi
}