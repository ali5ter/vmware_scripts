#!/usr/bin/env bash
# @file vic_setup.sh
# @author Alister Lewis-Bowen

set -e

# Download and position vic-machine build

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

CMD="$DIR/vic-machine-"
case "$OSTYPE" in
    darwin*) CMD="${CMD}darwin" ;;
    linux*)  CMD="${CMD}linux" ;;
    *)
        echo "$OSTYPE is not a supported operating system"
        exit 1
        ;;
esac
shopt -s expand_aliases
alias vic-machine="$CMD"

# Prompt for VC and credentials

echo
read -rp "Enter the address of your vCenter Server or ESXi host: " HOST

echo
read -rp "Enter the username you use to admnistrate this: " USERNAME

echo 
read -rp "Enter the password for this username: " PASSWD

# Get cert thumbprint and create auth strig

THUMB=$($PWD/../vsphere/show_thumbprint.sh $HOST| cut -d"=" -f 2)
AUTH='--target '"$HOST"' --user '"$USERNAME"' --password '"$PASSWD"' --thumbprint '"$THUMB"

# Configure firewall for VCH end-point access

echo 
read -rp "Enter the Cluster name you will use for VCHs: " CLUSTER

vic-machine update firewall $AUTH --compute-resource "$CLUSTER" --allow

# Store configuration

STORE=~/.vic_scripts_config
[ -f $STORE ] && rm -f "$STORE"
touch "$STORE"
echo "VIC_CLI=$CMD" >> "$STORE"
echo "VIC_HOST=$HOST" >> "$STORE"
echo "VIC_USER=$USERNAME" >> "$STORE"
echo "VIC_PASS=$PASSWD" >> "$STORE"
echo "VIC_THUMB=$THUMB" >> "$STORE"
echo "VIC_AUTH=$AUTH" >> "$STORE"
echo "VIC_CLUSTER=$CLUSTER" >> "$STORE"

echo
echo "Set up complete."
echo "Use the following alias to access the vic-machine CLI:"
echo "alias vic-machine=$CMD"
echo "Source the $STORE file to have access to the following env vars:"
echo env | grep VIC_