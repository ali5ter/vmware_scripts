#!/usr/bin/env bash

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

# clean up -------------------------------------------------------------------

heading "Remove existing smart clusters starting with $CLUSTER_PREFIX"
read -p "Shall I clear out all existing smart clusters? [y/N] " -n 1 -r
echo
[[ $REPLY =~ ^[Yy]$ ]] && "$PWD/cascade_cleanup.sh"

# create cluster -------------------------------------------------------------

## Create a name that's not too long since there's a bug that stops a cluster
## LB being deleted on AWS if the name is too long.

heading 'Create smart cluster and wait for it to be ready'

_name="${CLUSTER_PREFIX}-"$(curl -s https://raw.githubusercontent.com/ali5ter/vmware_scripts/master/photon_controller/generate_word_string.sh | bash -s 2)
_region=$(cascade --output json region list | jq '.[] | .name' | grep -i "$REGION_REGEX" | tr -d '"')
_version=$(cascade --output json version list -r "$_region" | jq '.items[] | select(.isDefault == true) | .version' | tr -d '"')
_size=$(( ( RANDOM % 4 ) + 1)) # a size between 1 and 4
_namespaces=$(( ( RANDOM % 8 ) + 1)) # a size between 1 and 8

cascade cluster create -t development -n "$_name" -r "$_region" -v "$_version" -s "$_size"

get_cluster_state() { echo $(cascade --output json cluster show "$_name" | jq '.details.state' | tr -d '"'); }

echo "Waiting for Smart Cluster to be ready..."
_cluster_state=''
until [ "$_cluster_state" == "READY" ]; do
    sleep 5
    _cluster_state=$(get_cluster_state)
    echo -e "\t$_cluster_state"
done

# create namespaces -----------------------------------------------------------

heading "Create some namespaces in $_name and retrieve namespaces using cascade CLI"
for i in $(seq "$_namespaces"); do
    cascade namespace create "$_name" "${_name}-namespace-$i"
done
cascade namespace list "$_name"

# connect to cluster ---------------------------------------------------------

heading "Generate kube config for smart cluster, $_name, and retrieve namespaces using kubectl"
cascade cluster get-kubectl-auth "$_name" -u "$USER" -f kube-config
export KUBECONFIG=./kube-config
kubectl cluster-info
kubectl get namespace