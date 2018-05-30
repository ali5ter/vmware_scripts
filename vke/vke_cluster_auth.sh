#!/usr/bin/env bash
# @file vke_cluster_auth.sh
# Create a kube configuration file for a selected Smart Cluster.
# @author Alister Lewis-Bowen <alister@lewis-bowen.org>

set -e

source "$PWD/vke_env.sh"

heading 'Authenticate with VMware Container Engine service'
"$PWD/vke_auth.sh"

# select a cluster -----------------------------------------------------------

_clusters="$(vke -o json cluster list | jq -r '.items[] | .name' | grep "$CLUSTER_PREFIX")"
_clusters_num=$(echo "$_clusters" | wc -l)
if [[ -z "$_clusters" ]]; then
    echo "Unable to find any clusters"
    exit 0
elif [[ "$_clusters_num" -eq 1 ]]; then
    _name="$_clusters"
else
    heading "Select from smart clusters starting with $CLUSTER_PREFIX"
    _cluster_index=1
    for cluster in $_clusters; do
        _aclusters[$_cluster_index]="$cluster"
        printf "    %3d ... %s\n" "$_cluster_index" "$cluster"
        ((_cluster_index++))
    done
    until [[ "$REPLY" =~ ^-?[0-9]+$ && "$REPLY" -gt 0 && "$REPLY" -lt "$(( ${#_aclusters[@]} + 1 ))" ]]; do
        read -p "Select one of these smart clusters [1-${#_aclusters[@]}]: " -n 1
        echo
    done
    _name=${_aclusters[$REPLY]}
fi

# generate kube context ------------------------------------------------------

heading "Create new context for smart cluster, $_name"
erun vke cluster merge-kubectl-auth "$_name"
echo -e '\tTo authenticate to this cluster, use the command:'
echo -e "\tkubectl config use-context "$_name"-context\n"
kubectl config use-context "$_name"-context

# check kubectl version compatibility ----------------------------------------

_kubeVersion=$(kubectl -o json version)
_platform=$(echo "$_kubeVersion" | jq -r '.clientVersion.platform' | sed 's#/#_#' )
_clientVersion=$(echo "$_kubeVersion" | jq -r '.clientVersion.major').$(echo "$_kubeVersion" | jq -r '.clientVersion.minor')
_serverVersion=$(echo "$_kubeVersion" | jq -r '.serverVersion.major').$(echo "$_kubeVersion" | jq -r '.serverVersion.minor')

[[ "$_clientVersion" != "$_serverVersion" ]] && {
    echo -e "\nThe kubectl client ($_clientVersion) and server ($_serverVersion) versions are different."
    echo -e "\tIf you encounter any compatibility problems because of this, download kubectl from:"
    echo -e -n "\t"
    vke -o json cluster show "$_name" | jq -r ".details.kubectlUrls.$_platform"
}

# dump some info about the cluster -------------------------------------------

heading "Information about smart cluster, $_name"

erun vke cluster show-health "$_name"

erun kubectl cluster-info

_admin=$(get_admin $_name)
echo -e "\nAdministrator(s) identities for $_name are:\n$_admin"