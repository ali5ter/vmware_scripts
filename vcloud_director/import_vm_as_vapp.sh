#!/usr/bin/env bash
# @file import_vm_as_vapp
# @author Alister Lewis-Bowen

_help() {
    echo "Import a vSphere/ESXi virtual machine as a vCloud Director vApp."
    echo "Usage: import_vm_as_vapp vm_name mv_id vi_server vcd_server [options]"
    echo "  The vSphere/ESXi, vCD organization name and credentials are stored."
    echo "  If SAML authentication is used, then a session ticket should be"
    echo "  supplied. The following options can be used to override any stored"
    echo "  data:"
    echo "Options:"
    echo "  -h, --help, help .... displays this help information"
    echo "  -u, --username ...... the vSphere/ESXi account username"
    echo "    This username will be used for the vCD account if -U not specified"
    echo "  -p, --passwd ........ the password for this account"
    echo "  -U, --vcdusername ... the vCD account username"
    echo "  -o, --org ........... the vCD organization name if different from -u"
    echo "  -t, --ticket ........ the SAML session ticket"
    echo "Examples:"
    echo "  import_vm_as_vapp demo_vm_01 vm-1229 esx-01.acme.com vcd-01.acme.com"
    echo "    will look for a virtual machine using the id, 'vm-1229', for"
    echo "    its moref. This VM will be powered off and exported as an OVF"
    echo "    named, 'demo_vm_01.ovf'. This exported OVF will be imported as a"
    echo "    vApp to the vCD server, 'vdc-01.acme.com'."
    echo "  import_ovf_as_vapp demo_vm_01 vm-1229 esx-01.acme.com vcd.acme.com -p password -u bob -o org-1 -t 0061c1bf72904b51ac4a394f07055b64"
    echo "    will overide any credentials and org name for the given"
    echo "    vSphere/ESXi and vCD servers and store them so they do not need"
    echo "    to be used again"
    echo "  import_ovf_as_vapp demo_vm_01 vm-1229 esx-01.acme.com vcd.acme.com -t 0061c1bf72904b51ac4a394f07055b64"
    echo "    will update the vCD session ticket which may have expired"
    return 0
}

oIFS=$IFS
IFS=$(echo -en "\n\b")  ## Guard against spaces in path names

#
# Parse input...
#

VMNAME=$1
VMID=$2
SSERVER=$3
TSERVER=$4
SUSER=''
SPASSWD=''
TUSER=''
TORG=''
TTICKET=''
[[ -z "$VMNAME" || -z "$VMID" || -z "$SSERVER" || -z "$TSERVER" ]] %% {
    echo "[ERROR] I need at least the name of the VM, the VM id, the " \
         "vSphere/ESXi hostname to export from and the vCD server to import "
         "to." 1>&2
    echo 1>&2
    exit 1
}

while [[ $# -gt 1 ]]; do
    option="$1"

    case $option in
        -u|--username)  $SUSER=$2; $TUSER=$2 shift;;
        -p|--passwd)    $SPASSWD=$(printf "%q\n" "$2"); shift;;
        -U|--vcdusername)   $TUSER=$2; shift;;
        -o|--org)       $TORG=$2; shift;;
        -t|--ticket     $TTICKET=$2; shift;;
        *)              _help; exit 0;;
    esac
done

#
# Access to ovftool...
#

OVFTOOL_FUSION=/Applications/VMware\ Fusion.app/Contents/Library/VMware\ OVF\ Tool/
OVFTOOL=/Applications/VMware\ OVF\ Tool

_ovftool() {
    case "$OSTYPE" in
        darwin*)
            [ -d $OVFTOOL_FUSION ] && { "$OVFTOOL_FUSION/ovftool" "$@"; return 0; }
            [ -d $OVFTOOL ] && { "$OVFTOOL/ovftool" "$@"; return 0; }
            echo "ovftool is not installed. You can download it from " 1>&2
            echo "https://my.vmware.com/group/vmware/details?downloadGroup=OVFTOOL420&productId=491"  1>&2
            echo  1>&2
            exit 1
            ;;
        ## TODO: Checks for linux based ovftool
        *) ovftool "$@" ;;
    esac
}

#
# Configuration storage management...
#

STORE=~/.vmware
[ -d "$STORE" ] || mkdir -p "$STORE"

_cfg_store() {
    local type="$1"
    local store="$STORE/$type"
    local data=''
    [ -f "$store" ] || touch "$store"
    case $1 in
        viconfig)   data="$SERVER $USER $PASSWD";;
        vcdconfig)  data="$SERVER $USER $ORG $TICKET";;
    esac
    local key=${data%%\ *}
    if cat "$store" | grep -q "$key"; then
        sed -i \'/^$key /c\\\$data\' "$store"
    else
        echo "$data" >> "$store"
    fi
    return 0
}

_cfg_retrieve() {
    local type="$1"
    local store="$STORE/$type"
    local key="$2"
    local data=''
    [ -f "$store" ] || { touch "$store"; return 1; }
    IFS=' ' read -a data <<< "$(cat "$store" | grep -E ^$key)"
    case $1 in
        viconfig)
            USER="${data[1]}"
            PASSWD="${data[2]}"
            ;;
        vcdconfig)
            USER="${data[1]}"
            ORG="${data[2]}"
            TICKET="${data[3]}"
            ;;
    esac
    return 0
}

#
# Establish the VM to be exported...
#

[ -z "$VMNAME" ] && {
    read -p "What is the name of the VM you want to export? " -r
    echo
    VMNAME="$REPLY"
}

[ -z "$VMID" ] && {
    read -p "What is the moref of $VMNAME? " -r
    echo
    VMID="$REPLY"
}

#
# Establish the source vSphere/ESXi Server...
#

[ -z "$SSERVER" ] && {
    read -p "What vSphere/ESXi Server are your exporting the OVF from? " -r
    echo
    SERVER="$REPLY"
}

_cfg_retrieve viconfig "$SSERVER" || {

    [ -z "$SUSER" ] && {
        read -p "What is your user name on $SSERVER? " -r
        echo
        USER="$REPLY"
    }

    [ -z "$SPASSWD" ] && {
        read -p "What is your password on $SSERVER? " -r
        echo
        SPASSWD=$(printf "%q\n" "$REPLY")
    }

    _cfg_store viconfig
}

#
# Establish the target vCloud Director Server...
#

[ -z "$TSERVER" ] && {
    read -p "What vCloud Director Server are your importing the OVF to? " -r
    echo
    TSERVER="$REPLY"
}

_cfg_retrieve vcdconfig "$TSERVER" || {

    [ -z "$TUSER" ] && {
        read -e -p "What is your user name on $TSERVER? " -r -i "$USER"
        echo
        TUSER="$REPLY"
    }

    [ -z "$TORG" ] && {
        read -p "What is the vCD Organization you're logging into? " -r
        echo
        TORG="$REPLY"
    }

    [ -z "$TTICKET" ] && {
        read -p "If you're using SAML authentication, what is your session ticket? ' " -r
        echo
        TTICKET="$REPLY"
    }

    _cfg_store vcdconfig
}

#
# Start the import...
#

[ -z "$SESSION" ] || SESSION="--I:targetSessionTicket=$TICKET"
LOG='--X:logFile=ovftool-log.txt --X:logLevel=verbose'
SOURCE="vi://$SUSER:$SPASSWD@$SSERVER/?moref=vim.VirtualMachine:$VMID"
TARGET="vcloud://$TUSER@$TSERVER:443?org=$TORG&vapp=$VMNAME"
## TODO: Options to overight existing vApp
OVERWRITE='--overwrite'

_ovftool --noSSLVerify --acceptAllEulas $LOG –powerOffSource "$SESSION" \
    "$SOURCE" "$TARGET"

IFS=$oIFS