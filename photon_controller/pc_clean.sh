#!/usr/bin/env bash
# @file pc_clean.sh
# Remove all objects from an instance
# @see https://github.com/vmware/photon-controller/wiki/Command-Line-Cheat-Sheet
# @author Alister Lewis-Bowen <alister@lewis-bowen.org>

type photon &> /dev/null || {
    echo "Please install photon CLI by downloading it from the release page at"
    echo "https://github.com/vmware/photon-controller/releases"
    echo "Add execute permissions and move into your path, e.g."
    echo "  chmod +x ~/Downloads/photon-darwin64-1.2-dd9d360"
    echo "  sudo mv ~/Downloads/photon-darwin64-1.2-dd9d360 /usr/local/bin/photon"
    exit 1
}

photon deployment list &> /dev/null || {
    echo "Set your Photon Platform target and log into it, e.g."
    echo "  photon target set -c https://192.168.0.10:443"
    echo "  photon target login --username administrator@local --password 'passwd'"
    exit 1
}

set -x

# Should be easier to get the name of an object...
for tenant in $(photon tenant list | grep -E "\w{8}-\w{4}-\w{4}-\w{4}-\w{12}" | awk '{print $2}'); do

    # Should be allowed to identify an object by it's name OR ID...
    photon tenant set "$tenant"

    for project in $(photon project list | grep -E "\w{8}-\w{4}-\w{4}-\w{4}-\w{12}" | awk '{print $2}'); do

        photon project set "$project"

        for service_id in $(photon service list | grep -Eo "\w{8}-\w{4}-\w{4}-\w{4}-\w{12}"); do

            # Strange that -n can mean both non-interactive AND name of the flavor
            # Even though these options are positional, this is very ambiguous for the user...
            photon -n service delete "$service_id"
        done

        for vm_id in $(photon vm list | grep -Eo "\w{8}-\w{4}-\w{4}-\w{4}-\w{12}"); do
            photon vm show "$vm_id" | grep -q STARTED && photon vm stop "$vm_id"
            for disk_id in $(photon disk list | grep -Eo "\w{8}-\w{4}-\w{4}-\w{4}-\w{12}"); do
                photon vm show "$vm_id" | grep -q "$disk_id" && \
                    photon vm detach-disk --disk "$disk_id" "$vm_id"
            done
            photon -n vm delete "$vm_id"
        done

        for disk_id in $(photon disk list | grep -Eo "\w{8}-\w{4}-\w{4}-\w{4}-\w{12}"); do
            photon -n disk delete "$disk_id"
        done

        # Should be easier to get IDs but also they're not consistent...
        for subnet_id in $(photon subnet list | grep -Eo "[0-9a-f]{21}"); do
            photon -n subnet delete "$subnet_id"
        done

        # Be nice to have a filter option to list non-default routers...
        for router_id in $(photon router list | grep false | grep -Eo "[0-9a-f]{21}"); do
            photon -n router delete "$router_id"
        done

        # Should be easier to get the ID of an object...
        photon -n project delete "$(photon project get | grep -Eo "\w{8}-\w{4}-\w{4}-\w{4}-\w{12}")"
    done

    photon -n tenant delete "$(photon tenant get | grep -Eo "\w{8}-\w{4}-\w{4}-\w{4}-\w{12}")"
done

set +x
read -p "Shall I delete all flavors? [y/N] " -n 1 -r
echo
[[ $REPLY =~ ^[Yy]$ ]] && {
    set -x
    for flavor_id in $(photon flavor list | grep -Eo "\w{8}-\w{4}-\w{4}-\w{4}-\w{12}"); do
        photon -n flavor delete "$flavor_id"
    done
    set +x
}

read -p "Shall I delete all images? [y/N] " -n 1 -r
echo
[[ $REPLY =~ ^[Yy]$ ]] && {
    set -x
    for image_id in $(photon image list | grep -Eo "\w{8}-\w{4}-\w{4}-\w{4}-\w{12}"); do
        photon -n image delete "$image_id"
    done
    set +x
}
