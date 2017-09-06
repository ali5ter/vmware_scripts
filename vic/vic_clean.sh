#!/usr/bin/env bash
# @file vic_clean.sh
# Remove all objects from an instance
# @author Alister Lewis-Bowen <alister@lewis-bowen.org>

set -e

source ~/.vic_scripts_config &> /dev/null || {
    "$PWD/vic_clean.sh"
}

read -p "Shall I delete all VCHs? [y/N] " -n 1 -r
echo
[[ $REPLY =~ ^[Yy]$ ]] && {
    set -x
    # should be easier to get the ID of a VCH...
    for vch in $("$VIC_CLI" ls | grep -E "^vm-" | awk '{print $1}'); do

        # this is very destructive action and should have more control, 
        # e.g. option not to delete the volume stores
        "$VIC_CLI" delete --id "$vch" --force
    done
    set +x
}