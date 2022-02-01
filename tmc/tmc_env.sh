#!/usr/bin/env bash
# @file tmc_env.sh
# Create an environment where these tmc scripts can work
# @author Alister Lewis-Bowen <alister@lewis-bowen.org>

[[ -n $DEBUG ]] && set -x
# @ref https://gist.github.com/mohanpedala/1e2ff5661761d3abd0385e8223e16425
set -eou pipefail

# shellcheck disable=SC1091
source tmc_config.sh || {
    echo "👍 Copying a sample configuration to './tmc_config.sh'"
    cp tmc_config_sample.sh tmc_config.sh
    echo "Please edit this config, follow the instructions found there and re-run this script."
    exit 1
}

# shellcheck disable=SC2034
TMC_SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

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
    return 0
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

check_stack() {
    read -p "${TMC_BOLD}✋ What stack do you want to use? [$TMC_STACK] " -r
    echo
    export TMC_STACK="${REPLY:-$TMC_STACK}"
    export TMC_CONTEXT="tmc-${TMC_STACK}"
    export TMC_API_ENDPOINT_HOSTNAME="tmc-users-${TMC_STACK}.tmc-dev.cloud.vmware.com"
    export TMC_API_ENDPOINT="https://${TMC_API_ENDPOINT_HOSTNAME}"
}

set_up() {
    heading "Create TMC context to authenticate with TMC service"

    local cmd

    # Check our tools are installed
    for cmd in tmc kubectl jq fzf; do
        command -v "$cmd" 1>/dev/null 2>&1 || {
            echo "🙄 Unable to find $cmd."
        exit 1
        }
    done

    check_stack

    # Use existing or create a new context
    export TMC_API_TOKEN="$CSP_API_TOKEN"
    if tmc system context list | grep "$TMC_CONTEXT" >/dev/null; then
        read -p "${TMC_BOLD}✋ Looks like context, $TMC_CONTEXT, exists. Want me to recreate it? [y/N] ${TMC_RESET}" -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            tmc system context delete "$TMC_CONTEXT" >/dev/null
            erun tmc login --stg-"$TMC_STACK" --name "$TMC_CONTEXT" --no-configure
        fi 
    else 
        erun tmc login --stg-"$TMC_STACK" --name "$TMC_CONTEXT" --no-configure
    fi
    echo

    # Update the context with defaults
    # !! Can't list defaults. Have to look in current context
    # !! Unable to set defaults independenty from each other
    # !! but even then, loglevel value is different
    # !! by trial and error, discovered you can unset defaults with no flags
    erun tmc configure -m "$TMC_MNGMT_CLUSTER" -p "$TMC_PROVISIONER" -l "$TMC_LOG_LEVEL"
    # context="$(tmc system context list)"
    # echo

    # Test if TMC API end-point is reachable
    erun tmc cluster list >/dev/null 2>/tmp/tmc-cluster-list.log || {
        echo "😱 Looks like the connnection filed while performing a CLI command..."
        tail -n1 /tmp/tmc-cluster-list.log
        exit 1
    }

    # # Check if context is updated after using it
    # echo "Show context content diff before and after auth..."
    # diff <( echo "$context" ) <( tmc system context list )
    # echo
}

context_detail() {
    # !! Extra work to extract some summary info for the context
    # !! Be nice if this were default output
    tmc system context current -o json > context.json
    echo "${TMC_BOLD}Tanzu Mission Control context information${TMC_RESET}"
    printf "  Organization ID:  %s\n" "$(jq -r .spec.orgId context.json)"
    printf "  Endpoint:         %s\n" "$(jq -r .spec.endpoint context.json)"
    printf "  Username:         %s\n" "$(jq -r .status.userName context.json)"
    printf "  Org perms:        \n%s\n" "$(jq -r .status.permissions context.json)"
    echo "  Defaults:"
    printf "    Management cluster:  %s\n" "$(jq -r .spec.env.MANAGEMENT_CLUSTER_NAME context.json)"
    printf "    Provisioner:         %s\n" "$(jq -r .spec.env.PROVISIONER_NAME context.json)"
    printf "    Log-level:           %s\n" "$(jq -r .spec.env.TMC_LOG_LEVEL context.json)"
    rm context.json
    echo

    # !! Be nice if there were some description of downloaded TMC KUBECONFIG
    #    files in a configurable location. Also provide cut and pastable alias
    echo "${TMC_BOLD}Kubeconfig files for TMC managed clusters${TMC_RESET}"
    local files=( "$TMC_KUBECONFIG_STORE_PREFIX"* )
    if [[ -e "${files[0]}" ]]; then
        for file in "${files[@]}"; do
            printf "   %s\talias='kubectl --kubeconfig=%s'\n" "$(basename "$file")"  "$file"
        done
    else
        echo "  none"
    fi
    echo

    # Calling out the difference between contexts
    echo "${TMC_BOLD}Local kubectl contexts${TMC_RESET}"
    erun kubectl config get-contexts
    echo
}

start_local_cluster() {
    heading "Make sure a local k8s cluster exists"
    # shellcheck disable=SC2155
    local cname="$(kind get clusters -q)"
    # shellcheck disable=SC2153
    if [ "$cname" == "$TMC_CLUSTER_NAME" ]; then
        read -p "${TMC_BOLD}✋ Looks like a kind cluster, $cname, exists. Want me to recreate it? [y/N] ${TMC_RESET}" -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            erun kind delete cluster --name="$cname" && \
            erun kind create cluster --config kind_config.yaml --name="$TMC_CLUSTER_NAME"
        fi 
    else 
        erun kind create cluster --config kind_config.yaml --name="$TMC_CLUSTER_NAME"
    fi
    echo
}

set_provider_to() {
    local provider="${1}"
    export TMC_PROVIDER="$provider"
    # shellcheck disable=SC2155
    # shellcheck disable=SC2086
    # shellcheck disable=SC2016
    export TMC_CLUSTER_NAME="$(grep CLUSTER_NAME tmc_config.sh | \
        cut -d'=' -f2 | \
        sed 's/\${TMC_PROVIDER}/'$TMC_PROVIDER'/' | \
        xargs)"
}

attach_local_cluster() {
    heading "Create cluster group $TMC_CLUSTER_GROUP unless it exists"

    # Create cluster group to manage policy on this cluster
    if tmc clustergroup list --all | grep "$TMC_CLUSTER_GROUP" >/dev/null; then
        echo "✅ Cluster group $TMC_CLUSTER_GROUP exists"
    else
        # !! name is not positional parameter
        # !! what does 'stringToString' mean in the help?
        erun tmc clustergroup create \
            -n "$TMC_CLUSTER_GROUP" -d "$TMC_DESCRIPTION" -l "$TMC_LABELS"
    fi

    heading "Attach local k8s cluster it isn't already"

    # Bring local cluster under TMC management
    if tmc cluster list --all | grep "$TMC_CLUSTER_NAME" >/dev/null; then
        echo "✅ Cluster $TMC_CLUSTER_NAME is already attached"
    else
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

        # Check if TMC installed agents provide healthy status
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

    # Update the cluster metadata
    # !! Still can't set the description
    # !! Description flag inconsistent with creation command
    # !! Help text should description label value format as, key1=value1,key2=value2...
    erun tmc cluster update "$TMC_CLUSTER_NAME" -m attached -p attached \
        --description "$TMC_DESCRIPTION" -l "$TMC_LABELS"

    # Apparently you can update using a template
    # tmc cluster template get attached
    # provides the attached template but there's no variable for description

    # Inspect cluster
    erun tmc cluster get "$TMC_CLUSTER_NAME" -m attached -p attached
}

get_aws_arn() {
    heading "Fetching AWS account ARN"

    AWS_CREDENTIALS="$HOME/.config/vmware-cloudgate-aws-vars.sh"

    if [[ -f "$AWS_CREDENTIALS" ]]; then
        # shellcheck disable=SC1090
        source "$AWS_CREDENTIALS"
    else
        echo "🙄 Unable to find AWS credentials at $AWS_CREDENTIALS"
        return 1
    fi

    if command -v aws 1>/dev/null 2>&1; then
        aws iam get-role --role-name "clusterlifecycle.tmc.cloud.vmware.com" | jq -r '.Role.Arn'
    else
        echo "🙄 Unable to find $cmd CLI."
        return 1
    fi    
}

get_cluster_summaries() {
    local cluster_search_token clusters

    # shellcheck disable=SC2016
    cluster_search_token="$(grep CLUSTER_NAME tmc_config.sh \
        | cut -d'=' -f2 \
        | sed 's/\${TMC_PROVIDER}//' \
        | xargs)"

    # shellcheck disable=SC2086
    tmc cluster list --all | grep $cluster_search_token
}

get_cluster_summary() {
    local clusters num_clusters

    clusters="$(get_cluster_summaries)"
    
    num_clusters="$(echo "$clusters" | wc -l | xargs)"

    case "$num_clusters" in
        0)
            echo "😱 Uanble to figure out what cluster to use"
            exit 1
            ;;
        1)
            echo "$clusters"
            ;;
        *)
            echo "$clusters" | fzf --height=40% --layout=reverse --info=inline --border 
            ;;
    esac
}

set_cluster() {
    echo "${TMC_BOLD}✋ Please select the cluster you would like to operate on ${TMC_RESET}"
    # shellcheck disable=SC2155
    local cluster="$(get_cluster_summary)"
    # shellcheck disable=SC2155
    # shellcheck disable=SC2086
    export TMC_CLUSTER_NAME="$(awk '{print $1}' <<< $cluster)"
    # shellcheck disable=SC2155
    # shellcheck disable=SC2086
    export TMC_MNGMT_CLUSTER="$(awk '{print $2}' <<< $cluster)"
    # shellcheck disable=SC2155
    # shellcheck disable=SC2086
    export TMC_PROVISIONER="$(awk '{print $3}' <<< $cluster)"
    echo "'$TMC_CLUSTER_NAME' selected"
    echo

    # Update the context with defaults
    # !! Can't list defaults. Have to look in current context
    # !! Unable to set defaults independenty from each other
    # !! but even then, loglevel value is different
    # !! by trial and error, discovered you can unset defaults with no flags
    erun tmc configure -m "$TMC_MNGMT_CLUSTER" -p "$TMC_PROVISIONER" -l "$TMC_LOG_LEVEL"

    # Grab the kubeconfig from TMC
    local kubeconfig_file="${TMC_KUBECONFIG_STORE_PREFIX}${TMC_CLUSTER_NAME}_${TMC_STACK}.yaml"
    if [[ "$TMC_MNGMT_CLUSTER" =~ attached|aws-hosted ]]; then
        # Could find local context if attached cluster is actually local
        #   kubectl config use-context $(kubectl config get-contexts | grep alb-dev-local)
        # Store kubeconfig from TMC for selected attached cluster
        erun tmc cluster auth kubeconfig get "$TMC_CLUSTER_NAME" > "$kubeconfig_file"
    else
        # Pulling kubeconfig from TMC for selected provisioned cluster
        erun tmc cluster auth admin-kubeconfig get "$TMC_CLUSTER_NAME" > "$kubeconfig_file"
    fi

    # Make sure kubectl uses kubeconfig so context works
    # shellcheck disable=SC2139
    local invocation="kubectl --kubeconfig $kubeconfig_file"
    # shellcheck disable=SC2139
    alias kubectl="$invocation"

    echo "🚨  all kubectl commands will actually use '$invocation'"
}

deploy_application() {
    [ "$(kubectl get ns nb 2>/dev/null | grep -c nb)" -eq 0 ] && {

        heading "Deploy a sample application to a local k8s cluster"

        [[ -d name-brainstormulator ]] && rm -fR name-brainstormulator
        erun git clone git@github.com:ali5ter/name-brainstormulator.git
        cd name-brainstormulator
        erun kubectl apply -f deployment.yaml
        cd .. && rm -fR name-brainstormulator
    }

    erun kubectl get pods,svc -n nb
    echo
}

remove_tmc_managed_cluster() {
    local cluster_name management_cluster provisioner
    cluster_name="${1:-$TMC_CLUSTER_NAME}"
    management_cluster="${2:-$TMC_MNGMT_CLUSTER}"
    provisioner="${3:-$TMC_PROVISIONER}"

    # Will use --force option on attached cluster because they are most
    # likely managing out local kind cluster that we can easily clean up
    # For those clusters we've provisioned we will have TMC attempt to clean
    # up the resources on the supporting IaS.
    if [[ "$management_cluster" == 'attached' ]]; then
        erun tmc cluster delete "$cluster_name" \
            -m "$management_cluster" \
            -p "$provisioner" \
            --force
    else
        erun tmc cluster delete "$cluster_name" \
            -m "$management_cluster" \
            -p "$provisioner"
    fi
}

_remove_tmc_managed_cluster_using_cluster_summary() {
    # TODO: Make this more of a general service function that can 
    # exract the management cluster and provisioner based on the 
    # cluster name. Use the JSON output which may be more reliable
    # than the formatted output and deal with duplicated cluster names

    local cluster_summary cluster_name management_cluster provisioner

    # This is content that comes from a line of output from the command
    #   tmc cluster list
    # and contains the cluster name, management cluster and provisioner
    cluster_summary="${1}"

    cluster_name="$(awk '{print $1}' <<< "$cluster_summary")"
    management_cluster="$(awk '{print $2}' <<< "$cluster_summary")"
    provisioner="$(awk '{print $3}' <<< "$cluster_summary")"

    remove_tmc_managed_cluster "$cluster_name" "$management_cluster" "$provisioner"
    rm -f "$HOME/.config/kubeconfig_${cluster_name}_${TMC_STACK}.yaml"
    
    erun kubectl config unset "contexts.${cluster_name}"
}

clean_up() {
    heading "Clean up cluster resources"

    local cluster_summary cluster_name management_cluster provisioner

    read -p "${TMC_BOLD}✋ Do you want me to delete/detach all clusters? [y/N] ${TMC_RESET}" -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        while read -r cluster_summary; do
            _remove_tmc_managed_cluster_using_cluster_summary "$cluster_summary"
        done <<< "$(get_cluster_summaries)"
    else
        echo "${TMC_BOLD}✋ Please select the cluster you would like to delete/detach ${TMC_RESET}"
        cluster_summary="$(get_cluster_summary)"
        cluster_name="$(awk '{print $1}' <<< "$cluster_summary")"
        echo "'$cluster_name' selected"
        echo
        _remove_tmc_managed_cluster_using_cluster_summary "$cluster_summary"
    fi
    echo

    # Leave TMC defaults in a standard state
    erun tmc configure -m attached -p attached -l "$TMC_LOG_LEVEL"

    # Clean up kubeconfig files
    rm -fR "$TMC_KUBECONFIG_STORE_PREFIX"*

    read -p "${TMC_BOLD}✋ Do you want me to delete the kind cluster, $TMC_CLUSTER_NAME? [y/N] ${TMC_RESET}" -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        erun kind delete cluster --name="$TMC_CLUSTER_NAME"
    fi
}