#!/usr/bin/env bash
# @file vke_populate.sh
# Populate a VMware Kubernetes Engine Project with a Smart Cluster and some Namespaces
# @author Alister Lewis-Bowen <alister@lewis-bowen.org>

set -e

source "$PWD/vke_env.sh"

heading 'Authenticate with VMware Kubernetes Service service'
"$PWD/vke_auth.sh"

# clean up -------------------------------------------------------------------

heading "Remove existing smart clusters starting with $CLUSTER_PREFIX"
read -p "Shall I clear out all existing smart clusters? [y/N] " -n 1 -r
echo
[[ $REPLY =~ ^[Yy]$ ]] && "$PWD/vke_cleanup.sh"

# create cluster -------------------------------------------------------------

## Create a name that's not too long since there's a bug that stops a cluster
## LB being deleted on AWS if the name is too long.

heading 'Create smart cluster and wait for it to be ready'

_name=$(curl -s https://raw.githubusercontent.com/ali5ter/vmware_scripts/master/photon_controller/generate_word_string.sh | bash -s 2)
_dname="${CLUSTER_DNAME_PREFIX}-${_name}"
_name="${CLUSTER_PREFIX}-${_name}"
_region=$(vke -o json info region list | jq -r '.items[] | .name' | grep -i "$REGION_REGEX")
## Will default to latest anyway but let's test the command to get the list of versions...
_version=$(vke -o json cluster versions list -r "$_region" | jq -r '.items[] | select(.isDefault == true) | .version')
_types=$(vke -o json cluster templates list | jq -r .items[].templateName)

## Name can only be up to 26 characters long :(
_name=$(echo "$_name" | cut -c 1-26)

## Select from cluster types
_type_index=1
for _type in $_types; do
    _atypes[$_type_index]="$_type"
    printf "    %3d ... %s\n" "$_type_index" "$_type"
    ((_type_index++))
done
until [[ "$REPLY" =~ ^-?[0-9]+$ && "$REPLY" -gt 0 && "$REPLY" -lt "$(( ${#_atypes[@]} + 1 ))" ]]; do
    read -p "Select one of these smart cluster types [1-${#_atypes[@]}]: " -n 1
    echo
done
_type=${_atypes[$REPLY]}

erun vke cluster create -t "$_type" -n "$_name" -d "$_dname" -r "$_region" -v "$_version"

get_cluster_state() { echo $(vke --output json cluster show "$_name" | jq -r '.details.state'); }

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

heading "Create some namespaces in $_name and retrieve namespaces using VKE CLI"
for i in $(seq "$_namespaces"); do
    erun vke cluster namespace create "$_name" "${_name}-namespace-$i"

done
erun vke cluster namespace list "$_name"

# connect to K8s cluster backing the smart cluster ---------------------------

heading "Create new context for smart cluster, $_name, and retrieve namespaces using kubectl"
erun vke cluster merge-kubectl-auth "$_name"
echo -e '\tTo authenticate to this cluster, use the command:'
echo -e "\tkubectl config use-context "$_name"-context"
erun kubectl config use-context "$_name"-context

# dump some info about the K8s cluster backing the smart cluster -------------

erun vke cluster show "$_name"
erun vke cluster show-health "$_name"
erun kubectl get namespace
erun kubectl cluster-info

_admin=$(get_admin $_name)
echo -e "/nAdministrator(s) identities for $_name are:\n$_admin"