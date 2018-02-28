#!/usr/bin/env bash
# @file cascade_cleanup.sh
# Delete previously created Smart Clsuters from a Cascade Project.
# @author Alister Lewis-Bowen <alister@lewis-bowen.org>

set -e

source "$PWD/cascade_env.sh"

heading 'Authenticate with Cascade service'
"$PWD/cascade_authenticate.sh"

## There doesn't seem to be a way to get the display name from a json output 
## of smart clusters

set +e

for cluster in $(cascade --output json cluster list | jq -r '.[] | .name' | grep "$CLUSTER_PREFIX"); do
    read -p "Delete $cluster? [y/N] " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]] && cascade cluster delete "$cluster"
done