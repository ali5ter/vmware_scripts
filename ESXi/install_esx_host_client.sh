#!/usr/bin/env bash
# @file install_esx_host_client.sh
# Download and install the ESXi html client and patch
# @see https://labs.vmware.com/flings/esxi-embedded-host-client
# @author Alister Lewis-Bowen <alister@lewis-bowen.org>

set -e

is_installed() {
    # @see https://gist.github.com/JamieMason/4761049
    local return_=1
    type "$1" >/dev/null 2>&1 || { local return_=0; }
    echo $return_
}

download_to_file() {
    local url=$1
    local file=$2
    if [ "$(is_installed curl)" -eq 1 ]; then
        curl -Lso "$file" "$url"
    else
        wget -Oq "$url" "$file"
    fi
}

checksum() {
    local file=$1
    if [ "$(is_installed md5)" -eq 1 ]; then
        md5 "$file" | cut -d' ' -f 4
    else
        md5sum "$file" | cut -d' ' -f1
    fi
}

ESXHOST="$1"

[ ! -n "$ESXHOST" ] && {
    echo
    echo "This script depends on SSH being enabled on your ESXi host."
    echo "Please CNTRL-C out of this script and enable SSH now if you want to continue."
    echo
    read -rp "What is the address or IP of the ESXi host? " ESXHOST
}

ACCESS="root@$ESXHOST"

# ============================================================================
# Download VIB and push it to ESXi host
# NOTE: This is done because the ESXi host may not have internet access

VIB="/tmp/esxui.vib"
[ ! -f "$VIB" ] && {
    echo
    echo "Downloading the VIB"
    URL="http://download3.vmware.com/software/vmw-tools/esxui/esxui-signed.vib"
    download_to_file "$URL" "$VIB"
}

echo
echo "VIB stored in $VIB"

echo
echo "Copying VIB to your ESXi host"
CHECKSUM=$(checksum "$VIB")
scp -q "$VIB" "$ACCESS":"$VIB"

# ============================================================================
# Install VIB and patch the http proxy endpoints file

echo
echo "Installing and configuring the VIB"

ssh "$ACCESS" \
        _VIB="$VIB" \
        _CHECKSUM="$CHECKSUM" \
        'sh -s' << 'END_OF_REMOTE_SCRIPT'

set -e

## Install the VIB

if [ "$(esxcli software vib list | grep -c esx-ui)" -ne 0 ]; then
    esxcli software vib remove -n esx-ui > /dev/null
fi

CHECKSUM=$(md5sum "$_VIB" | cut -d' ' -f1)
if [ "$CHECKSUM" != "$_CHECKSUM" ]; then
    echo "VIB was corrupted when copied to the ESXi host"
    exit 1
fi

esxcli software vib install -v "$_VIB" > /dev/null

## Patch http proxy endpoints
ENDPOINTS="/etc/vmware/rhttpproxy/endpoints.conf"

mv "$ENDPOINTS" "$ENDPOINTS".bak
cp "$ENDPOINTS".bak "$ENDPOINTS"

sed -i '/^\/ui/d' "$ENDPOINTS"

/etc/init.d/rhttpproxy restart > /dev/null 2>&1

## Clean up
rm -fr "$_VIB"

END_OF_REMOTE_SCRIPT

echo
echo "ESXi Embedded Host Client is installed"
echo "Access it using https://$ESXHOST/ui/"
echo
