#!/usr/bin/env bash
# @file cascade_cluster_auth.sh
# Create a kube configuration file for a selected Smart Cluster.
# @author Alister Lewis-Bowen <alister@lewis-bowen.org>

set -e

source "$PWD/cascade_env.sh"

heading 'Authenticate with Cascade service'
"$PWD/cascade_authenticate.sh"

# list clusters -------------------------------------------------------------

heading "Select from smart clusters starting with $CLUSTER_PREFIX"
_cluster_index=1
for cluster in $(cascade --output json cluster list | jq -r '.[] | .name' | grep "$CLUSTER_PREFIX"); do
    _clusters[$_cluster_index]="$cluster"
    printf "    %3d ... %s\n" "$_cluster_index" "$cluster"
    ((_cluster_index++))
done
until [[ "$REPLY" -gt 0 && "$REPLY" -lt "$(( ${#_clusters[@]} + 1 ))" ]]; do
    read -p "Select one of these smart clusters [1-${#_clusters[@]}]: " -n 1
    echo
done
_name=${_clusters[$REPLY]}

# generate kube config -------------------------------------------------------

heading "Generate kube config for smart cluster, $_name"
cascade cluster get-kubectl-auth "$_name" -u "$USER" -f kube-config
echo -e '\texport KUBECONFIG=./kube-config'

# dump some info about the cluster -------------------------------------------

heading "Information about smart cluster, $_name"
export KUBECONFIG=./kube-config
kubectl cluster-info

## There are some deprecated objects in the iam JSON response that need to be
## cleared out

_admin=$(cascade --output json cluster iam show "$_name" | jq -r '.direct.bindings[] | select(.role == "smartcluster.admin") | .subjects[]')
[[ -z "$_admin" ]] && {
    _admin=$(cascade --output json cluster iam show "$_name" | jq -r '.inherited[].bindings[] | select(.role == "smartcluster.admin") | .subjects[]')
}
echo -e "\nAdministrator(s) identities for $_name are:\n$_admin"