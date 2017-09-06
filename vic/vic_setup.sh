#!/usr/bin/env bash
# @file vic_setup.sh
# @author Alister Lewis-Bowen
# Testing with VIC v1.2
# @see https://vmware.github.io/vic-product/assets/files/html/1.2/

set -e

STORE=~/.vic_scripts_config
[ -f $STORE ] && source "$STORE" ## to use as defaults

# Download and position vic-machine build
# @see https://vmware.github.io/vic-product/assets/files/html/1.2/vic_vsphere_admin/download_vic.html

VIC_MACHINE_DOWNLOAD='https://storage.googleapis.com/vic-engine-builds/vic_13605.tar.gz'
VIC_MACHINE_COMPLETION_DOWNLOAD='https://raw.githubusercontent.com/ali5ter/cli_taxo/master/exp4/results/vic-machine_completion.sh'
BINARY_FILE="${VIC_MACHINE_DOWNLOAD##*/}"
BASH_COMPLETION="${VIC_MACHINE_COMPLETION_DOWNLOAD##*/}"
DIR="/usr/local/vic"
RUNCOM=~/.bash_profile

read -p "Do you want to download the latest binaries? [y/N]" -n 1 -r
[[ $REPLY =~ ^[Yy]$ ]] && {
    echo
    echo "Downloading vic-engine binaries"
    curl -k "$VIC_MACHINE_COMPLETION_DOWNLOAD" -o "$BINARY_FILE" && \
        tar -zxf "$BINARY_FILE" && rm -f "$BINARY_FILE"
    echo "Moving vic-engine binaries to $DIR"
    sudo rm -fR "$DIR"
    sudo mv vic*/ "$DIR"
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

echo
echo "Use the following alias to access the vic-machine CLI:"
echo "alias vic-machine='$VIC_CLI'"
echo
read -rp "Do you want to add this to $RUNCOM ? [y/N] " -n 1 -r
[[ $REPLY =~ ^[Yy]$ ]] && {
    echo -e "\n# VIC CLI\nalias vic-machine=$VIC_CLI" >> "$RUNCOM"
}
echo

# Prompt for VC and credentials

echo
read -rp "Enter the address of your vCenter Server or ESXi host [$VIC_MACHINE_TARGET]: "
[ ! -z "$REPLY" ] && VIC_MACHINE_TARGET="$REPLY"

echo
read -rp "Enter the username you use to admnistrate this [$VIC_MACHINE_USER]: "
[ ! -z "$REPLY" ] && VIC_MACHINE_USER="$REPLY"

echo 
read -rp "Enter the password for this username [$VIC_MACHINE_PASSWORD]: "
[ ! -z "$REPLY" ] && VIC_MACHINE_PASSWORD="$REPLY"

# Get cert thumbprint and create auth string

VIC_MACHINE_THUMBPRINT=$($PWD/../vsphere/show_thumbprint.sh $VIC_MACHINE_TARGET| cut -d"=" -f 2)

# Configure firewall for VCH end-point access
# @see https://vmware.github.io/vic-product/assets/files/html/1.2/vic_vsphere_admin/open_ports_on_hosts.html

echo 
read -rp "Enter the Cluster name you will use for VCHs [$VIC_CLUSTER]: "
[ ! -z "$REPLY" ] && $VIC_CLUSTER="$REPLY"

AUTH='--target '"$VIC_MACHINE_TARGET"' --user '"$VIC_MACHINE_USER"' --password '"$VIC_MACHINE_PASSWORD"' --thumbprint '"$VIC_MACHINE_THUMBPRINT"

echo
echo "Configuring vCenter host firewall rules for VIC..."
"$VIC_CLI" update firewall $VIC_AUTH --compute-resource "$VIC_CLUSTER" --allow

# Store configuration

[ -f $STORE ] && rm -f "$STORE"
touch "$STORE" && chmod 755 "$STORE"
echo "export VIC_CLI='$VIC_CLI'" >> "$STORE"
echo "export VIC_MACHINE_TARGET='$VIC_MACHINE_TARGET'" >> "$STORE"
echo "export VIC_MACHINE_USER='$VIC_MACHINE_USER'" >> "$STORE"
echo "export VIC_MACHINE_PASSWORD='$VIC_MACHINE_PASSWORD'" >> "$STORE"
echo "export VIC_MACHINE_THUMBPRINT='$VIC_MACHINE_THUMBPRINT'" >> "$STORE"
echo "export VIC_CLUSTER='$VIC_CLUSTER'" >> "$STORE"

echo
echo "Set up complete."
echo
echo "The $STORE file contains exports for the following env vars:"
env | grep VIC_
echo
echo "With the credentials set up using env vars, the invocation from the CLI"
echo "is much simpler, e.g. vic-machine ls"
echo
read -rp "Do you want to source this from $RUNCOM ? [y/N] " -n 1 -r
[[ $REPLY =~ ^[Yy]$ ]] && {
    echo -e "\n# VIC vars\nsource $STORE" >> "$RUNCOM"
}
echo
echo
read -rp "Do you want to use bash completion for vic-machine ? [y/N] " -n 1 -r
[[ $REPLY =~ ^[Yy]$ ]] && {
    curl -k "$VIC_MACHINE_COMPLETION_DOWNLOAD" -o "$BASH_COMPLETION"
    echo
    echo "To use enable completion immediately, run the following"
    echo "source <(cat $BASH_COMPLETION)"
    echo
    read -rp "Do you want to source this from $RUNCOM ? [y/N] " -n 1 -r
    [[ $REPLY =~ ^[Yy]$ ]] && {
        echo -e "\n# vic-machine completion\nsource $PWD/$BASH_COMPLETION" >> "$RUNCOM"
    }
    echo
}
