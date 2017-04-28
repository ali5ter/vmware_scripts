#!/usr/bin/env bash
# @file pc_create_flavors.sh
# Create some useful Photon Controller Flavors
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

# Strange that -n can mean both non-interactive AND name of the flavor
# Even though these options are positional, this is very ambiguous for the user...
photon -n flavor create --kind vm --name tiny-vm --cost "vm.cpu 1 COUNT, vm.memory 512 MB, vm.cost 1 COUNT"
photon -n flavor create --kind vm --name small-vm --cost "vm.cpu 1 COUNT, vm.memory 1 MB, vm.cost 2 COUNT"
photon -n flavor create --kind vm --name medium-vm --cost "vm.cpu 2 COUNT, vm.memory 2 MB, vm.cost 3 COUNT"
photon -n flavor create --kind vm --name large-vm --cost "vm.cpu 2 COUNT, vm.memory 4 MB, vm.cost 4 COUNT"

photon -n flavor create --kind ephemeral-disk --name vm-disk --cost "ephemeral-disk 1 COUNT, ephemeral-disk.flavor.vm-disk 1 COUNT, ephemeral-disk.cost 1 COUNT"
photon -n flavor create --kind ephemeral-disk --name cluster-vm-disk --cost "ephemeral-disk 1 COUNT, ephemeral-disk.flavor.cluster-vm-disk 1 COUNT, ephemeral-disk.cost 1 COUNT"

photon -n flavor create --kind persistent-disk --name vm-disk --cost "persistent-disk 1 COUNT, persistent-disk.flavor.vm-disk 1 COUNT, persistent-disk.cost 1 COUNT"

photon flavor list
