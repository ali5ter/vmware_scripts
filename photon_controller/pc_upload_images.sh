#!/usr/bin/env bash
# @file pc_create_flavors.sh
# Upload images to an instance
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

ASSETS_DIR="$PWD/assets"

# Downloaded from https://github.com/vmware/photon/wiki/Downloading-Photon-OS
PHOTON_IMAGE="$ASSETS_DIR/photon-custom-hw10-1.0-62c543d.ova"

# Downloaded from https://github.com/vmware/photon-controller/releases/tag/v1.2.0
KUBE_IMAGE="$ASSETS_DIR/kubernetes-1.4.3-pc-1.1.0-5de1cb7.ova"

# Strange that -n can mean both non-interactive AND name of the flavor
# Even though these options are positional, this is very ambiguous for the user...
photon -n image create --name photon1 --image_replication EAGER "$PHOTON_IMAGE" &

# A default image replication value would decrease amount of typing...
photon -n image create --name kube1 --image_replication ON_DEMAND "$KUBE_IMAGE" &

# It would be great to have an async option

# Interesting that the action subcommand is 'create' and not 'upload'

# TODO upload image to a project

photon image list
