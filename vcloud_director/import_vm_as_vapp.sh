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
    echo "  --overwrite  ........ overwrite the existing vApp"
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
            err "https://my.vmware.com/group/vmware/details?downloadGroup=OVFTOOL420&productId=491"
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
        -u|--username)  SUSER=$2; shift;;
        -p|--passwd)    SPASSWD=$(printf "%q\n" "$2"); shift;;
        -U|--vcdusername)   TUSER=$2; shift;;
        -o|--org)       TORG=$2; shift;;
        -t|--ticket)    TTICKET=$2; shift;;
        --overwrite)    OVERWRITE='--overwrite'; shift;;
        -h|--help|help) _help; exit 1;;
        *)  # positional args
            if [ -z "$VMNAME" ]; then VMNAME=$1;
            elif [ -z "$VMID" ]; then VMID=$1;
            elif [ -z "$SSERVER" ]; then SSERVER=$1;
            elif [ -z "$TSERVER" ]; then TSERVER=$1; fi
            ;;
    esac
    shift
done

[ -z "$TUSER" ] && TUSER="$SUSER"

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
        viconfig)   data="$SSERVER $SUSER $SPASSWD";;
        vcdconfig)  data="$TSERVER $TUSER $TORG $TTICKET";;
    esac
    local key=${data%%\ *}
    if cat "$store" | grep -q "$key"; then
        sed -i \'/^$key/c\\\$data\' "$store"
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
    [[ ${#data[@]} -eq 0 ]] && return 1
    case $1 in
        viconfig)
            [ -z "$SUSER" ] && SUSER="${data[1]}"
            [ -z "$SPASSWD" ] && SPASSWD="${data[2]}"
            ;;
        vcdconfig)
            [ -z "$TUSER" ] && TUSER="${data[1]}"
            [ -z "$TORG" ] && TORG="${data[2]}"
            [ -z "$TTICKET" ] && TTICKET="${data[3]}"
            ;;
    esac
    return 0
}

#
# Establish the VM to be exported...
#

[ -z "$VMNAME" ] && {
    echo "The name of the VM is used as the resulting vApp name."
    read -p "What is the name of the VM you want to export? " -r
    echo
    VMNAME="$REPLY"
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

[ -z "$SSERVER" ] && {
    read -p "What is the hostname/IP of the vSphere/ESXi server are your exporting the OVF from? " -r
    echo
    SSERVER="$REPLY"
}

_cfg_retrieve viconfig "$SSERVER" || {

    [ -z "$SUSER" ] && {
        read -p "What is your user name on $SSERVER? " -r
        echo
        SUSER="$REPLY"
    }

    [ -z "$SPASSWD" ] && {
        read -p "What is your password on $SSERVER? " -r
        echo
        SPASSWD=$(printf "%q\n" "$REPLY")
    }    
}
_cfg_store viconfig

#
# Establish the target vCloud Director Server...
#

[ -z "$TSERVER" ] && {
    read -p "What is the hostname/IP of the vCloud Director server are you importing the OVF to? " -r
    echo
    TSERVER="$REPLY"
}

_cfg_retrieve vcdconfig "$TSERVER" || {

    [ -z "$TUSER" ] && {
        read -e -p "What is your user name on $TSERVER? " -r -i "$SUSER"
        echo
        TUSER="$REPLY"
    }

    [ -z "$TORG" ] && {
        read -p "What is the vCD Organization you're logging into? " -r
        echo
        TORG="$REPLY"
    }

    [ -z "$TTICKET" ] && {
        echo "You will be asked for the password to your account but this may"
        echo "not work if SAML authentication is being used. If this is the case,"
        echo "I will need your session ticket. Find this by logging into your"
        echo "vCD web client, open the tool you use to inspect cookies and"
        echo "supply the browser cookie value called 'VMware Session Ticket'."
        read -p "If you're using SAML authentication, what is your session ticket? " -r
        echo
        TTICKET="$REPLY"
    }
}
 _cfg_store vcdconfig

#
# Start the migration...
#

[ -z "$TTICKET" ] || SESSION="--I:targetSessionTicket=$TTICKET"
SOURCE="vi://$SUSER:$SPASSWD@$SSERVER/?moref=vim.VirtualMachine:$VMID"
TARGET="vcloud://$TUSER@$TSERVER:443?org=$TORG&vapp=$VMNAME"

"$OVFTOOL" --noSSLVerify --acceptAllEulas \
    --X:logFile=ovftool-log.txt --X:logLevel=verbose $SESSION \
    $OVERWRITE --powerOffSource "$SOURCE" "$TARGET"