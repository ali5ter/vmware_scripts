#!/usr/bin/env bash
# @file vic_setup.sh
# @author Alister Lewis-Bowen
# Testing with VIC v1.2
# @see https://vmware.github.io/vic-product/assets/files/html/1.2/

set -e

STORE=~/.vic_scripts_config
source "$STORE" ## to use as defaults

# Download and position vic-machine build
# @see https://vmware.github.io/vic-product/assets/files/html/1.2/vic_vsphere_admin/download_vic.html

BUILD=vic_13400
FILE="$BUILD".tar.gz
DIR="/usr/local/vic"

read -p "Do you want to download the latest binaries? [y/N]" -n 1 -r
[[ $REPLY =~ ^[Yy]$ ]] && {
    echo
    echo "Downloading vic-engine binaries"
    curl -k "https://storage.googleapis.com/vic-engine-builds/$FILE" -o "$FILE" && \
        tar -zxf "$FILE" && rm -f "$FILE"
    echo "Moving vic-engine binaries to $DIR"
    sudo rm -fR "$DIR"
    sudo mv vic "$DIR"
}
echo

# Determin which platform binary to access

VIC_CLI="$DIR/vic-machine-"
case "$OSTYPE" in
    darwin*) VIC_CLI="${VIC_CLI}darwin" ;;
    linux*)  VIC_CLI="${VIC_CLI}linux" ;;
    msys*)  VIC_CLI="${VIC_CLI}windows" ;;
    *)
        echo "$OSTYPE is not a supported operating system"
        exit 1
        ;;
esac
shopt -s expand_aliases
alias vic-machine="$VIC_CLI"

# Prompt for VC and credentials

echo
read -rp "Enter the address of your vCenter Server or ESXi host [$VIC_HOST]: "
[ ! -z "$REPLY" ] && $VIC_HOST="$REPLY"

echo
read -rp "Enter the username you use to admnistrate this [$VIC_USER]: "
[ ! -z "$REPLY" ] && $VIC_USER="$REPLY"

echo 
read -rp "Enter the password for this username [$VIC_PASS]: "
[ ! -z "$REPLY" ] && $VIC_PASS="$REPLY"

# Get cert thumbprint and create auth string

VIC_THUMB=$($PWD/../vsphere/show_thumbprint.sh $VIC_HOST| cut -d"=" -f 2)
VIC_AUTH='--target '"$VIC_HOST"' --user '"$VIC_USER"' --password '"$VIC_PASS"' --thumbprint '"$VIC_THUMB"

# Configure firewall for VCH end-point access
# @see https://vmware.github.io/vic-product/assets/files/html/1.2/vic_vsphere_admin/open_ports_on_hosts.html

echo 
read -rp "Enter the Cluster name you will use for VCHs [$VIC_CLUSTER]: "
[ ! -z "$REPLY" ] && $VIC_CLUSTER="$REPLY"

echo
echo "Configuring vCenter host firewall rules for VIC..."
vic-machine update firewall $VIC_AUTH --compute-resource "$VIC_CLUSTER" --allow

# Store configuration

[ -f $STORE ] && rm -f "$STORE"
touch "$STORE"
echo "export VIC_CLI='$VIC_CLI'" >> "$STORE"
echo "export VIC_HOST='$VIC_HOST'" >> "$STORE"
echo "export VIC_USER='$VIC_USER'" >> "$STORE"
echo "export VIC_PASS='$VIC_PASS'" >> "$STORE"
echo "export VIC_THUMB='$VIC_THUMB'" >> "$STORE"
echo "export VIC_AUTH='$VIC_AUTH'" >> "$STORE"
echo "export VIC_CLUSTER='$VIC_CLUSTER'" >> "$STORE"
source "$STORE"

echo
echo "Set up complete."
echo
echo "Use the following alias to access the vic-machine CLI:"
echo "alias vic-machine='$VIC_CLI'"
echo
echo "Use the VIC_AUTH env var to include your vCenter credentials, e.g. vic-machine ls \$VIC_AUTH"
echo
echo "The $STORE file contains exports for the following env vars:"
env | grep VIC_
