#!/usr/bin/env bash
# @file cascade_cluster_auth.sh
# Create a kube configuration file for a selected Smart Cluster.
# @author Alister Lewis-Bowen <alister@lewis-bowen.org>

set -e

source "$PWD/cascade_config.sh"

type jq &> /dev/null || {
    echo 'Please install jq which is available from https://stedolan.github.io/jq/download/'
    exit 1
}

heading 'Authenticate with Cascade service'
"$PWD/cascade_authenticate.sh"

# navigate to correct scope --------------------------------------------------

## Now that output is tabulated with lots more visual chars, it's easier to
## output in json and use jq to extract attributes needed

## Notice that some json responses use an anonymous array and some use an array
## called 'items'

## A pain that values are wrapped in quotes - means extra work to take them off

heading 'Navigate to correct project scope'
cascade folder set $(cascade --output json folder list | jq '.items[] | .name' | grep -i "$FOLDER_REGEX" | tr -d '"')
cascade project set $(cascade --output json project list | jq '.[] | .name' | grep -i "$PROJECT_REGEX" | tr -d '"')

# list clusters -------------------------------------------------------------

heading "Select from smart clusters starting with $CLUSTER_PREFIX"
_cluster_index=1
for cluster in $(cascade --output json cluster list | jq '.[] | .name' | grep "$CLUSTER_PREFIX" | tr -d '"'); do
    _clusters[$_cluster_index]="$cluster"
    printf "    %3d ... %s\n" "$_cluster_index" "$cluster"
    ((_cluster_index++))
done
until [[ "$REPLY" -gt 0 && "$REPLY" -lt "$(( ${#_clusters[@]} + 1 ))" ]]; do
    read -p "Select one of these smart clusters [1-${#_clusters[@]}]: " -n 1
    echo
done
_name=${_clusters[$REPLY]}

# dump some info about the cluster -------------------------------------------

heading "Information about smart cluster, $_name"

kubectl cluster-info

## There are some deprecated objects in the iam JSON response that need to be
## cleared out

_admin=$(cascade --output json cluster iam show "$_name" | jq '.direct.bindings[] | select(.role == "smartcluster.admin") | .subjects[]')
[[ -z "$_admin" ]] && {
    _admin=$(cascade --output json cluster iam show "$_name" | jq '.inherited[].bindings[] | select(.role == "smartcluster.admin") | .subjects[]')
}
echo -e "\nAdministrator(s) identities for $_name are:\n$_admin"

# generate kube config -------------------------------------------------------

heading "Generate kube config for smart cluster, $_name"
cascade cluster get-kubectl-auth "$_name" -u "$USER" -f kube-config
echo -e '\texport KUBECONFIG=./kube-config'
