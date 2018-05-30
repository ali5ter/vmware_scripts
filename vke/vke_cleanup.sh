#!/usr/bin/env bash
# @file vke_cleanup.sh
# Delete previously created Smart Clusters from a VMware Container Engine Project.
# @author Alister Lewis-Bowen <alister@lewis-bowen.org>

set -e

source "$PWD/vke_env.sh"

heading 'Authenticate with VMware Container Engine service'
"$PWD/vke_auth.sh"

## There doesn't seem to be a way to get the display name from a json output 
## of smart clusters

set +e

for cluster in $(vke --output json cluster list | jq -r '.items[] | .name' | grep "$CLUSTER_PREFIX"); do
    read -p "Delete $cluster? [y/N] " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]] && erun vke cluster delete "$cluster"
done