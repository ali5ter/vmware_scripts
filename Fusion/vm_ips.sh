#!/usr/bin/env bash
# @file vm_ips.sh
# Echo the IPs of guests running in Fusion VMs
# @see https://www.vmware.com/support/developer/vix-api/vix112_vmrun_command.pdf
# @author Alister Lewis-Bowen <alister@lewis-bowen.org>

oIFS=$IFS
IFS=$(echo -en "\n\b")

vmrun=/Applications/VMware\ Fusion.app/Contents/Library/vmrun
[ -e "$vmrun" ] || {
    echo "Fusion is not installed"
    exit 1
}

vm_list=$($vmrun list | grep vmx)

for vm in $vm_list; do
    echo "$($vmrun getGuestIPAddress $vm) : '$vm'"
done

IFS=$oIFS
