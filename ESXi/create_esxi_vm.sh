#!/usr/bin/env sh
# @file create_esxi_vm.sh
# Create a virtual machine on an ESXi host
# Based on original work by Tamas Piros (tamaspiros)
# @see https://github.com/tamaspiros/auto-create
# @author Alister Lewis-Bowen <alister@lewis-bowen.org>

set -e

vCPU=1
MEMORY=1024
STORAGE=16
DATASTORE="/vmfs/volumes/datastore1"
ISO_PATH=""

help() {
    echo
    echo "Create a virtual machine on an ESXi host"
    echo
    echo "Usage:"
    echo "  create_esxi_vm.sh -n <name> [-c <number_of_vcpus>] [-m <memory_in_mb>] [-s <storage_in_gb>] [-d <datastore_path>] [-i <iso_filepath>]"
    echo "  create_esxi_vm.sh -h"
    echo
    echo "Options:"
    echo "  -n  Name of the virtual machine."
    echo "  -c  Number of virtual CPUs from 1 to 32 [default: $vCPU]."
    echo "  -m  Memory capacity in MB [default: $MEMORY]."
    echo "  -s  Storage capacity in GB, thin provisioned [default: $STORAGE]."
    echo "  -d  Datastore path [default: $DATASTORE]."
    echo "  -i  Filepath of an ISO file used to install the operating system."
    echo
}

# ============================================================================
# Parse and validate options

while getopts n:c:m:s:i:h opt; do
    case $opt in
        n)
            NAME=${OPTARG};
            if [ -z "$NAME" ]; then
                echo "No name was specified for the virtual machine"
                exit 1
            fi
            ;;
        c)
            vCPU=${OPTARG}
            if [ $(echo "$vCPU" | egrep "^-?[0-9]+$") ]; then
                if [ "$vCPU" -lt "1" ] || [ "$vCPU" -gt "32" ]; then
                    echo "Virtual CPUs must be between 1 and 32"
                    exit 1
                fi
            else
                echo "Virtual CPUs must be an integer value"
                exit 1
            fi
            ;;
        m)
            MEMORY=${OPTARG}
            if [ $(echo "$MEMORY" | egrep "^-?[0-9]+$") ]; then
                if [ "$MEMORY" -lt "1" ]; then
                    echo "Assigned memory must be 1MB or more"
                    exit 1
                fi
            else
                echo "Memory capacity must be an integer value"
                exit 1
            fi
            ;;
        s)
            STORAGE=${OPTARG}
            if [ $(echo "$STORAGE" | egrep "^-?[0-9]+$") ]; then
                if [ "$STORAGE" -lt "1" ]; then
                    echo "Assigned storage must be 1GB or more"
                    exit 1
                fi
            else
                echo "Storage capacity must be an integer value"
                exit 1
            fi
            ;;
        d)  DATASTORE=${OPTARG}
            if [ ! -d "$DATASTORE" ]; then
                echo "Datastore path does not exist"
                exit 1
            fi
            ;;
        i)
            ISO_PATH=${OPTARG}
            if [ ! -f "$ISO_PATH" ]; then
                echo "$ISO_PATH does not exist"
            fi
            ;;
        h)  help; exit 1;;
        \?) echo "Unknown option: -$OPTARG" >&2; help; exit 1;;
        :)  echo "Missing option argument for -$OPTARG" >&2; help; exit 1;;
        *)  echo "Unimplimented option: -$OPTARG" >&2; help; exit 1;;
    esac
done

if [ -z "$NAME" ]; then
    echo "Provide a name for the virtual name"
    exit 1
fi

VM_DIR="$DATASTORE/$NAME"
if [ -d "$VM_DIR" ]; then
    echo
    echo "This already exists at $VM_DIR"
    echo
    echo "You can remove this directory but remember to unregister it first:"
    echo "1. List the VM id using 'vim-cmd /vmsvc/getallvms'"
    echo "2. Then unregister it using 'vim-cmd /vmsvc/unregister <Vmid>'"
    ## @see http://www.yellow-bricks.com/2011/11/16/esxi-commandline-work/
    echo
    exit
fi

# ============================================================================
# Confirmation

echo
echo "A virtual machine will be created using this specification:"
echo "  Name:     $NAME"
echo "  vCPUs:    $vCPU"
echo "  Memory:   ${MEMORY}MB"
echo "  Storage:  ${STORAGE}GB"
if [ -n "$ISO_PATH" ]; then
    echo "  ISO file: $ISO_PATH"
fi
echo
echo "The virtual machine will be located at $VM_DIR"
echo
echo "Do you want to continue? [y|n]"
read -r answer
if [ "$answer" != "y" ]; then exit 1; fi
echo

# ============================================================================
# Virtual machine build environment

VMDK="$VM_DIR/$NAME.vmdk"
DEFAULT_VMX="default.vmx"
VMX="$VM_DIR/$NAME.vmx"

if [ ! -f "$DEFAULT_VMX" ]; then
    wget -O "$DEFAULT_VMX" http://gitlab.different.com/alister/ubuntu_install_tools/raw/master/default.vmx
fi

mkdir -p "$VM_DIR"

# ============================================================================
# Construct the vmdk and vmx files

vmkfstools -c "$STORAGE"G -a lsilogic "$VMDK"

cp "$DEFAULT_VMX" "$VMX"
sed -i "s%{{name}}%$NAME%g" "$VMX"
sed -i "s%{{vcpu}}%$vCPU%g" "$VMX"
sed -i "s%{{memory}}%$MEMORY%g" "$VMX"
sed -i "s%{{storage}}%$STORAGE%g" "$VMX"
sed -i "s%{{iso_path}}%$ISO_PATH%g" "$VMX"

# ============================================================================
# Register the virtual machine and power it on

CMD="$(vim-cmd solo/registervm $VMX)"
vim-cmd vmsvc/power.on "$CMD"

echo "Virtual machine creation complete"
