#!/usr/bin/env bash
# @file cascade_populate.sh
# Populate a Cascade Project with a Smart Cluster and some Namespaces
# @author Alister Lewis-Bowen <alister@lewis-bowen.org>

set -e

source "$PWD/cascade_env.sh"

heading 'Authenticate with Cascade service'
"$PWD/cascade_authenticate.sh"

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
_region=$(cascade --output json info region list | jq -r '.items[] | .name' | grep -i "$REGION_REGEX")
_version=$(cascade --output json version list -r "$_region" | jq -r '.items[] | select(.isDefault == true) | .version')
_size=$(( ( RANDOM % 4 ) + 1)) # a size between 1 and 4

## Name can only be up to 26 characters long :(
_name=$(echo "$_name" | cut -c 1-26)

erun cascade cluster create -t development -n "$_name" -r "$_region" -v "$_version" -s "$_size"

get_cluster_state() { echo $(cascade --output json cluster show "$_name" | jq -r '.details.state'); }

## Sometime find I can't add namespaces until the smart cluster is 'ready', so 
## poll the state...

echo "Waiting for Smart Cluster to be ready..."
_cluster_state=''
until [ "$_cluster_state" == "READY" ]; do
    sleep 20
    _cluster_state=$(get_cluster_state)
    echo -e "\t$_cluster_state"
done

# create namespaces -----------------------------------------------------------

_namespaces=$(( ( RANDOM % 8 ) + 1)) # a size between 1 and 8

heading "Create some namespaces in $_name and retrieve namespaces using cascade CLI"
for i in $(seq "$_namespaces"); do
    erun cascade namespace create "$_name" "${_name}-namespace-$i"
done
erun cascade namespace list "$_name"

# connect to K8s cluster backing the smart cluster ---------------------------

heading "Create new context for smart cluster, $_name, and retrieve namespaces using kubectl"
erun cascade cluster merge-kubectl-auth "$_name"
echo -e '\tTo authenticate to this cluster, use the command:'
echo -e "\tkubectl config use-context "$_name"-context"
erun kubectl config use-context "$_name"-context

# dump some info about the K8s cluster backing the smart cluster -------------

erun kubectl cluster-info
erun kubectl get namespace

## There are some deprecated objects in the iam JSON response that need to be
## cleared out

_get_admin() {
    local policy=$(cascade --output json cluster iam show alb-acetylize-benzal | jq -r '.inherited[].bindings[]')
    local admin=$(echo $policy | jq 'select(.role == "smartcluster.admin") | .subjects[]')
    if [[ -z "$_admin" ]] then
        admin=$(echo $policy | jq 'select(.role == "project.admin") | .subjects[]')
    elif [[ -z "$_admin" ]] 
        admin=$(echo $policy | jq 'select(.role == "folder.admin") | .subjects[]')
    else [[ -z "$_admin" ]] then
        admin=$(echo $policy | jq 'select(.role == "tenant.admin") | .subjects[]')
    fi
    if [[ -z "$_admin" ]] then
        return 0
    else 
        echo "$admin"
        return 1
    fi
}

_admin=$(cascade --output json cluster iam show "$_name" | jq -r '.direct.bindings[] | select(.role == "smartcluster.admin") | .subjects[]')
[[ -z "$_admin" ]] && _admin=$(_get_admin)
echo -e "Administrator(s) identities for $_name are:\n$_admin"