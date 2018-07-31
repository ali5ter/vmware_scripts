#!/usr/bin/env bash
# @file export_vm_to_ovf
# @author Alister Lewis-Bowen

_help() {
    echo "Export a virtual machine as an OVF from a vSphere or ESXi server."
    echo "Usage: export_vm_to_ovf vm_name vm_id vi_server [options]"
    echo "  The vSphere/ESXi credentials are stored."
    echo "  The following options can be used to override any stored data:"
    echo "Options:"
    echo "  -h, --help, help ... displays this help information"
    echo "  -u, --username ..... the vSphere/ESXi account username"
    echo "  -p, --passwd ....... the password for this account"
    echo "  --overwrite ........ overwrite the existing OVF"
    echo "Examples:"
    echo "  export_vm_to_ovf demo_vm_01 vm-1229 esx-01.acme.com"
    echo "    will look for a virtual machine using the id, 'vm-1229', for"
    echo "    its moref. This VM will be powered off and exported as an OVF"
    echo "    named, 'demo_vm_01.ovf'"
    echo "  import_ovf_as_vapp vm_01 vm-42 vsphere.acme.com -u bob -p password"
    echo "    will overide any credentials for the given vSphere/ESXi server"
    echo "    and store them so they do not need to be used again"
    return 0
}

err() { echo "$@" 1>&2; }

#
# Access to ovftool...
#

OVFTOOL_FUSION=/Applications/VMware\ Fusion.app/Contents/Library/VMware\ OVF\ Tool/ovftool
OVFTOOL_OSX=/Applications/VMware\ OVF\ Tool/ovftool
OVFTOOL_LINUX=ovftool

case "$OSTYPE" in
    darwin*)
        if [ -d "$(dirname "$OVFTOOL_FUSION")" ]; then OVFTOOL="$OVFTOOL_FUSION"; 
        elif [ -d "$(dirname "$OVFTOOL_OSX")" ]; then OVFTOOL="$OVFTOOL_OSX";
        else
            err "[ERROR] ovftool is not installed. You can download it from "
            err "https://my.vmware.com/web/vmware/details?downloadGroup=OVFTOOL420&productId=614"
            err
            exit 1
        fi
        ;;
    *) OVFTOOL="$OVFTOOL_LINUX";;
esac

#
# Parse input...
#

while [[ $# -gt 0 ]]; do
    arg="$1"
    case $arg in
        -u|--username)  UNAME=$2; shift;;
        -p|--passwd)    PASSWD=$2; shift;;
        --overwrite)    OVERWRITE='--overwrite';;
        -h|--help|help) _help; exit 1;;
        *)  # positional args
            if [ -z "$VMNAME" ]; then VMNAME=$1;
            elif [ -z "$VMID" ]; then VMID=$1;
            elif [ -z "$SERVER" ];then SERVER=$1; fi
            ;;
    esac
    shift
done

#
# Configuration storage management...
#

STORE=~/.vmware
[ -d "$STORE" ] || mkdir -p "$STORE"

_cfg_store() {
    local store="$STORE/viconfig"
    local data="$SERVER $UNAME $PASSWD"
    local key=${data%%\ *}
    [ -f "$store" ] || touch "$store"
    if cat "$store" | grep -q "$key"; then
        sed -i"" -e "s/^$key.*/$data/" "$store"
    else
        echo "$data" >> "$store"
    fi
    return 0
}

_cfg_retrieve() {
    local store="$STORE/viconfig"
    local key="$1"
    local data
    [ -f "$store" ] || { touch "$store"; return 1; }
    IFS=' ' read -a data <<< "$(cat "$store" | grep -E ^$key)"
    [[ ${#data[@]} -eq 0 ]] && return 1
    [ -z "$UNAME" ] && UNAME="${data[1]}"
    [ -z "$PASSWD" ] && PASSWD="${data[2]}"
    return 0
}

#
# Establish the VM to be exported...
#

[ -z "$VMNAME" ] && {
    echo "The name of the VM is used as the OVF filename."
    read -p "What is the name of the VM you want to export? " -r
    echo
    VMNAME="$REPLY"
}

OVFSTORE="$STORE/images"
[ -d $OVFSTORE ] || mkdir "$OVFSTORE"

OVF="$OVFSTORE/$VMNAME.ovf"
[ -f $OVF ] && {
    echo "[WARNING] I already have an OVF that uses this VM name:"
    echo "$OVF"
    read -p "Shall I continue anyway? [y/N] " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]] || exit 1
    echo
    OVERWRITE='--overwrite'
}

[ -z "$VMID" ] && {
    echo "To effectively identify the VM, I need the VM ID (aka moref)."
    echo "Navigate to the VM object in the web client and the VM id will"
    echo "appear in the URL, e.g vm-42"
    read -p "What is the vm id (aka moref) of $VMNAME? " -r
    echo
    VMID="$REPLY"
}

#
# Establish the source vSphere/ESXi Server...
#

[ -z "$SERVER" ] && {
    read -p "What is the hostname/IP of the vSphere/ESXi server are your exporting the OVF from? " -r
    echo
    SERVER="$REPLY"
}

_cfg_retrieve "$SERVER" || {

    [ -z "$UNAME" ] && {
        read -p "What is your user name on $SERVER? " -r
        echo
        UNAME="$REPLY"
    }

    [ -z "$PASSWD" ] && {
        read -p "What is your password on $SERVER? " -r
        echo
        PASSWD="$REPLY"
    }
}
_cfg_store

#
# Start the export...
#

SOURCE="vi://$UNAME:$PASSWD@$SERVER/?moref=vim.VirtualMachine:$VMID"

"$OVFTOOL" --noSSLVerify --X:logFile=ovftool-log.txt --X:logLevel=verbose \
    $OVERWRITE --powerOffSource "$SOURCE" "$OVF"