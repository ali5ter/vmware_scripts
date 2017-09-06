#!/usr/bin/env bash
# @file vic_populate.sh
# Populate an instance with some objects
# @author Alister Lewis-Bowen <alister@lewis-bowen.org>

set -e

source ~/.vic_scripts_config &> /dev/null || {
    "$PWD/vic_setup.sh"
}

read -p "Shall I clear out all existing objects from this instance? [y/N] " -n 1 -r
echo
[[ $REPLY =~ ^[Yy]$ ]] && "$PWD/vic_clean.sh"

NUM_VCHS=2
VCH_NAMES=$(seq $NUM_VCHS | xargs -Iz "$PWD/../photon_controller/generate_word_string.sh" 2)
TIMEOUT="6m"

set -x

for vch in $VCH_NAMES; do
    "$VIC_CLI" create --name "$vch" --bridge-network "$VIC_BRIDGE_NETWORK" \
        --image-store "$VIC_IMAGE_DATASTORE" --timeout "$TIMEOUT" \
        --no-tlsverify --force
done

# should be easier to get the ID of a VCH...
for vch in $("$VIC_CLI" ls | grep -E "^vm-" | awk '{print $1}'); do
    "$VIC_CLI" inspect --id "$vch"
done

set +x