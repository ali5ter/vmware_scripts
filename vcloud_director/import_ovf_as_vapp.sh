#!/usr/bin/env bash
# @file import_ovf_as_vapp
# @author Alister Lewis-Bowen

_help() {
    echo "Import an OVF as a vCloud Director vApp."
    echo "Usage: import_ovf_as_vapp vm_name vcd_server [options]"
    echo "  The vCD organization name and credentials are stored. If SAML"
    echo "  authentication is used, then a session ticket should be supplied."
    echo "  The following options can be used to override any stored data:"
    echo "Options:"
    echo "  -h, --help, help ... displays this help information"
    echo "  -u, --username ..... the vCD account username"
    echo "  -o, --org .......... the vCD organization name"
    echo "  -t, --ticket ....... the SAML session ticket"
    echo "  --overwrite  ....... overwrite the existing vApp"
    echo "Examples:"
    echo "  import_ovf_as_vapp demo_vm_01 vcd-01.acme.com"
    echo "    will look for a previously exported OVF for a VM named"
    echo "    'demo_vm_01' and import this as a vApp to the vCD server,"
    echo "    'vdc-01.acme.com'. If the OVF is not found, you will be prompted"
    echo "    to start a helper script to export the OVF"
    echo "  import_ovf_as_vapp vm_01 vcd.acme.com -u bob -o org-1 -t 0061c1bf72904b51ac4a394f07055b64"
    echo "    will overide any credentials and org name for the given vCD"
    echo "    server and store them so they do not need to be used again"
    echo "  import_ovf_as_vapp vm_01 vcd.acme.com -t 0061c1bf72904b51ac4a394f07055b64"
    echo "    will update the session ticket which may have expired"
    return 0
}

err() { echo "$@" 1>&2; }

#
# Access to ovftool...
#

OVFTOOL_FUSION=/Applications/VMware\ Fusion.app/Contents/Library/VMware\ OVF\ Tool/ovftool
OVFTOOL_OSX=/Applications/VMware\ OVF\ Tool/ovftool
OVFTOOL=LINUX=ovftool

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
        -o|--org)       ORG=$2; shift;;
        -t|--ticket)    TICKET=$2; shift;;
        --overwrite)    OVERWRITE='--overwrite';;
        -h|--help|help) _help; exit 1;;
        *)  # positional args
            if [ -z "$VMNAME" ]; then VMNAME=$1;
            elif [ -z "$SERVER" ]; then SERVER=$1; fi
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
    local store="$STORE/vcdconfig"
    local data="$SERVER $UNAME $ORG $TICKET"
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
    local store="$STORE/vcdconfig"
    local key="$1"
    local data
    [ -f "$store" ] || { touch "$store"; return 1; }
    IFS=' ' read -a data <<< "$(cat "$store" | grep -E ^$key)"
    [[ ${#data[@]} -eq 0 ]] && return 1
    [ -z "$UNAME" ] && UNAME="${data[1]}"
    [ -z "$ORG" ] && ORG="${data[2]}"
    [ -z "$TICKET" ] && TICKET="${data[3]}"
    return 0
}

#
# Establish the OVF to import...
#

[ -z "$VMNAME" ] && {
    echo "The name of the VM is used as the OVF filename."
    read -p "What's the name of the VM you want to import? " -r
    echo
    VMNAME="$REPLY"
}

OVFSTORE="$STORE/images"
[ -d "$OVFSTORE" ] || mkdir -p "$OVFSTORE"

OVF="$OVFSTORE/$VMNAME.ovf"
[ -f $OVF ] || {
    err "[ERROR] I am unable to find an OVF file that uses this VM name:"
    err "$OVF"
    err "These are the OVFs I found:"
    err $(ls -1 "$OVFSTORE"/*.ovf)
    exit 1
    ## TODO: Run export from vsphere?
}

#
# Establish the target vCloud Director Server...
#

[ -z "$SERVER" ] && {
    read -p "What is the hostname/IP of the vCloud Director server are you importing the OVF to? " -r
    echo
    SERVER="$REPLY"
}

_cfg_retrieve "$SERVER" || {

    [ -z "$UNAME" ] && {
        read -p "What is your user name on $SERVER? " -r
        echo
        UNAME="$REPLY"
    }

    [ -z "$ORG" ] && {
        read -p "What is the vCD Organization you are logging into? " -r
        echo
        ORG="$REPLY"
    }

    [ -z "$TICKET" ] && {
        echo "You will be asked for the password to your account but this may"
        echo "not work if SAML authentication is being used. If this is the case,"
        echo "I will need your session ticket. Find this by logging into your"
        echo "vCD web client, open the tool you use to inspect cookies and"
        echo "supply the browser cookie value called 'Vmware_session_id'."
        read -p "If you're using SAML authentication, what is your session ticket? " -r
        echo
        TICKET="$REPLY"
    }
}
_cfg_store

#
# Start the import...
#

[ -z "$TICKET" ] || SESSION="--I:targetSessionTicket=$TICKET"
TARGET="vcloud://$UNAME@$SERVER:443?org=$ORG&vapp=$VMNAME"

"$OVFTOOL" --noSSLVerify --acceptAllEulas \
    --X:logFile=ovftool-log.txt --X:logLevel=verbose $SESSION \
    --maxVirtualHardwareVersion=10 \
    $OVERWRITE "$OVF" "$TARGET"