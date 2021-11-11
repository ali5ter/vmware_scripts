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

erun() {
    ( set -x; "$@"; )
    echo
}

api_get() {
    # Standard API GET
    # @ref https://developer.vmware.com/apis/1079/tanzu-mission-control
    local method="$1"
    curl -sSX GET -H "Authorization: Bearer $CSP_ACCESS_TOKEN" \
    "${TMC_API_ENDPOINT}${method}"
}

set_up() {
    heading "Create TMC context to authenticate with TMC service"

    local cmd context

    # Check our tools are installed
    for cmd in tmc kubectl jq; do
        command -v "$cmd" 1>/dev/null 2>&1 || {
            echo "🙄 Unable to find $cmd."
        exit 1
        }
    done

    # Create fresh context
    tmc system context list | grep "$TMC_CONTEXT" >/dev/null && \
        tmc system context delete "$TMC_CONTEXT" >/dev/null
    export TMC_API_TOKEN="$CSP_API_TOKEN"
    erun tmc login --stg-unstable --name "$TMC_CONTEXT" --no-configure

    # Update the context with defaults
    # !! Can't list defaults. Have to look in current context
    # !! Unable to set defaults independenty from each other
    # !! but even then, loglevel value is different
    # !! by trial and error, discovered you can unset defaults with no flags
    erun tmc configure -m "$TMC_MNGMT_CLUSTER" -p "$TMC_PROVISIONER" -l "$TMC_LOG_LEVEL"
    context="$(tmc system context list)"
    echo

    # Test if TMC API end-point is reachable
    tmc cluster list 1>/dev/null 2>/dev/null || {
        echo "😱 Looks like the connnection filed while performing a CLI update."
        exit 1
    }

    # Check if context is updated after using it
    echo "Show context content diff before and after auth..."
    diff <( echo "$context" ) <( tmc system context list )
    echo
}

context_detail() {
    # !! Extra work to extract some summary info for the context
    # !! Be nice if this were default output
    heading "Context detail"
    tmc system context current -o json > context.json
    printf "Organization ID:  %s\n" "$(jq -r .spec.orgId context.json)"
    printf "Endpoint:         %s\n" "$(jq -r .spec.endpoint context.json)"
    printf "Username:         %s\n" "$(jq -r .status.userName context.json)"
    printf "Org perms:        %s\n" "$(jq -r .status.permissions context.json)"
    echo "Defaults:"
    printf "Management cluster:  %s\n" "$(jq -r .spec.env.MANAGEMENT_CLUSTER_NAME context.json)"
    printf "Provisioner:         %s\n" "$(jq -r .spec.env.PROVISIONER_NAME context.json)"
    printf "Log-level:           %s\n" "$(jq -r .spec.env.TMC_LOG_LEVEL context.json)"
    rm context.json
    echo
}

start_local_cluster() {
    heading "Make sure a local k8s cluster exists"
    # shellcheck disable=SC2155
    local cname="$(kind get clusters -q)"
    # shellcheck disable=SC2153
    if [ "$cname" == "$TMC_CLUSTER_NAME" ]; then
        read -p "${TMC_BOLD}✋ Looks like a kind cluster, $cname, exists. Want me to delete this one? [y/N] ${TMC_RESET}" -n 1 -r
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

attach_local_cluster() {
    heading "Create cluster group $TMC_CLUSTER_GROUP unless it exists"

    # Create cluster group to manage policy on this cluster
    if tmc clustergroup list --all | grep "$TMC_CLUSTER_GROUP" >/dev/null; then
        echo "Cluster group $TMC_CLUSTER_GROUP exists"
    else
        # !! name is not positional parameter
        # !! what does 'stringToString' mean in the help?
        erun tmc clustergroup create \
            -n "$TMC_CLUSTER_GROUP" -d "$TMC_DESCRIPTION" -l "$TMC_LABELS"
    fi

    heading "Attach local k8s cluster it isn't already"

    # Bring local cluster under TMC management
    if ! tmc cluster list --all | grep "$TMC_CLUSTER_NAME" >/dev/null; then
        # !! name is not positional parameter
        # !! no description option
        # !! can't get label option to work
        # !! what does 'stringToString' mean in the help?
        erun tmc cluster attach -n "$TMC_CLUSTER_NAME" -g "$TMC_CLUSTER_GROUP"
        #    -d "$TMC_DESCRIPTION" -l "$TMC_LABELS"
        sleep 5
        erun kubectl apply -f k8s-attach-manifest.yaml
        rm k8s-attach-manifest.yaml

        # List tmc pods and services before connection to TMC
        erun kubectl get pods,svc -n vmware-system-tmc

        # Check if TMC can see this cluster
        # !! output flag not documented
        echo -n "Checking TMC thinks $TMC_CLUSTER_NAME is ready"
        # shellcheck disable=SC2086
        while [ "$(tmc cluster get $TMC_CLUSTER_NAME \
                -m attached -p attached \
                -o json | jq -r .status.phase)" != 'READY' ]; do
            echo -n '.'
            sleep 10
        done
        echo ' ✅'
        echo

        # List tmc pods and services after connection to TMC
        erun kubectl get pods,svc -n vmware-system-tmc

        # Check if TMC can see this cluster
        # !! output flag not documented
        echo -n "Checking TMC thinks $TMC_CLUSTER_NAME is healthy"
        # shellcheck disable=SC2086
        while [ "$(tmc cluster get $TMC_CLUSTER_NAME \
                -m attached -p attached \
                -o json | jq -r .status.health)" != 'HEALTHY' ]; do
            echo -n '.'
            sleep 10
        done
        echo ' ✅'
        echo
    fi

    # Inspect cluster
    erun tmc cluster get "$TMC_CLUSTER_NAME" -m attached -p attached
}

deploy_application() {
    [ "$(kubectl get ns nb 2>/dev/null | grep -c nb)" -eq 0 ] && {
        heading "Deploy a sample application to a local k8s cluster"
        erun git clone git@github.com:ali5ter/name-brainstormulator.git
        cd name-brainstormulator
        erun kubectl apply -f deployment.yaml
        cd .. && rm -fR name-brainstormulator
    }
    erun kubectl get pods,svc -n nb
    echo
}

clean_up() {
    heading "Clean up cluster resources"

    # TODO: Check cluster still attached
    read -p "${TMC_BOLD}✋ Do you want me to detach $TMC_CLUSTER_NAME? [y/N] ${TMC_RESET}" -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        erun tmc cluster delete "$TMC_CLUSTER_NAME" -m attached -p attached \
            --force
    fi
    echo

    read -p "${TMC_BOLD}✋ Do you want me to delete the kind cluster, $TMC_CLUSTER_NAME? [y/N] ${TMC_RESET}" -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        kind delete cluster --name="$TMC_CLUSTER_NAME"
    fi
}