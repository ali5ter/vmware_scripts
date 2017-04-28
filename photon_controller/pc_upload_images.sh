#!/usr/bin/env bash
# @file pc_upload_images.sh
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

# TODO: Cater for wget on non-Darwin systems

upload_photon_image() {
    [[ $REPLY =~ ^[Yy]$ ]] && "$PWD/pc_create_flavors.sh"
    # Downloaded from https://github.com/vmware/photon/wiki/Downloading-Photon-OS
    PHOTON_IMAGE_URL="https://bintray.com/vmware/photon/download_file?file_path=photon-custom-hw10-1.0-62c543d.ova"
    PHOTON_IMAGE="$ASSETS_DIR/photon.ova"
    [ ! -f "$PHOTON_IMAGE" ] && curl -L -o "$PHOTON_IMAGE" "$PHOTON_IMAGE_URL"

    set -x
    # Strange that -n can mean both non-interactive AND name of the flavor
    # Even though these options are positional, this is very ambiguous for the user...
    photon -n image create --name photon1 --image_replication EAGER "$PHOTON_IMAGE" &
    set +x
}

upload_kube_image() {
    # Downloaded from https://github.com/vmware/photon-controller/releases/tag/v1.2.0
    KUBE_IMAGE_URL="https://github.com/vmware/photon-controller/releases/download/v1.2.0/kubernetes-1.6.0-pc-1.2-dd9d360.ova"
    KUBE_IMAGE="$ASSETS_DIR/kubernetes.ova"
    [ ! -f "$KUBE_IMAGE" ] && curl -L -o "$KUBE_IMAGE" "$KUBE_IMAGE_URL"

    set -x
    # A default image replication value would decrease amount of typing...
    photon -n image create --name kube1 --image_replication ON_DEMAND "$KUBE_IMAGE" &
    set +x
}

# It would be great to have an async option

# Interesting that the action subcommand is 'create' and not 'upload'

# TODO upload image to a project

ASSETS_DIR="$PWD/assets"

echo "Let me know what image configuration you would like:"
echo "  [1] Just a PhotonOS image for your VMs"
echo "  [2] Just a Kubernetes image for your K8s Cluster Services"
echo "  [3] Both PhotonOS and Kubernetes images"
echo "  [4] Don't upload any images right now"
read -p "Which option would you like me to perform? [1/2/3/4] " -n 1 -r
echo
case "$REPLY" in
    1) upload_photon_image ;;
    2) upload_kube_image ;;
    3) upload_photon_image; upload_kube_image ;;
    *) exit 0 ;;
esac

sleep 2
echo "Watch images uploading using a command like:"
echo "  while true; do clear; photon image list; sleep 5; done"
