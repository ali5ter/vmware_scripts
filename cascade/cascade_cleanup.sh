#!/usr/bin/env bash
# @file cascade_cleanup.sh
# Delete previously created Smart Clsuters from a Cascade Project.
# @author Alister Lewis-Bowen <alister@lewis-bowen.org>

set -e

source "$PWD/cascade_config.sh"

type jq &> /dev/null || {
    echo 'Please install jq which is available from https://stedolan.github.io/jq/download/'
    exit 1
}

"$PWD/cascade_authenticate.sh"

## There doesn't seem to be a way to get the display name from a json output 
## of smart clusters

set +e

for cluster in $(cascade --output json cluster list | jq '.[] | .name' | grep "$CLUSTER_PREFIX" | tr -d '"'); do
    read -p "Delete $cluster? [y/N] " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]] && cascade cluster delete "$cluster"
done