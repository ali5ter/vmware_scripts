# VMware ESXi scripts

Scripts used in conjunction with [VMware ESXi](https://www.vmware.com/products/vsphere--hypervisor).

Tested for installations of: 
* ESXi 5.x
* ESXi 6.x

**These scripts often assume that you have [enabled SSH and ESXi Shell](http://kb.vmware.com/selfservice/microsites/search.do?language=en_US&cmd=displayKC&externalId=2004746)
on the ESXi host.**

## Show ESXi specifications
**The [show_esxi_specs](show_esxi_specs) script displays routing, dns, datastore
and portgroup information for a given ESXi host.**

This script issues simple [esxcli](https://pubs.vmware.com/vsphere-50/index.jsp?topic=%2Fcom.vmware.vcli.ref.doc_50%2Fesxcli_command.html)
commands via ssh to echo information. The certificate thumbprint is also echo'ed [using openssl](http://www.virtuallyghetto.com/2012/04/extracting-ssl-thumbprint-from-esxi.html).

Download the script to your workstation

    curl -Os http://gitlab.different.com/alister/vmware_scripts/raw/master/ESXi/show_esxi_specs
    
The script is run in a couple of ways

    ./show_esxi_specs-host
    ./show_esxi_specs-host <esxi_host_address>

## Install the ESXi Embedded Client Host
**The [install_esxi_host_client](install_esxi_host_client) script installs the
[ESXi Embedded Client Host](https://labs.vmware.com/flings/esxi-embedded-host-client)
onto an ESXi host from a remote machine.**

This script prompts for the address of the ESXi host, downloads the ESXi
Embedded Client Host VIB, copies this VIB to your ESXi host and remotely
performs the installation and any configuration needed.

Download the script to your workstation

    curl -Os http://gitlab.different.com/alister/vmware_scripts/raw/master/ESXi/install_esxi_host_client
    
The script is run in a couple of ways

    ./install_esxi_client-host
    ./install_esxi_client-host <esxi_host_address>

## Create a virtual machine
**The [create_esxi_vm](create_esxi_vm) script allows you to create a virtual 
machine from the command line instead of through one of the VMware UIs.**

This script generates the files needed to create a virtual machine and register 
it with the ESXi system. The the [default.vmx](default.vmx) file provides a
template specification for the virtual machine.

*It has been used to conveniently stand up fresh Ubuntu Server VMs using [ISOs
created for unattended installation and configured using a post installation
script](http://gitlab.different.com/alister/ubuntu_install_tools/tree/master#unattended-installation-iso-creation).*

### VM creation from the ESXi cmdl
Log into the ESXi server and download the script like this

    wget -q http://gitlab.different.com/alister/vmware_scripts/raw/master/ESXi/create_esxi_vm && chmod 755 create_esxi_vm

Create a virtual machine using the vCPU, memory and storage defaults using one
of the installation ISOs like this

    ./create_esxi_vm -n server_01 -i /vmfs/volumes/datastore1/ISOs/ubuntu-14.04.3-server-amd64-unattended.iso

For help about changing the defaults run

    ./create_esxi_vm -h

Once complete, the virtual machine will automically power on.

### Remote VM creation
[documentation to come]

## Contribution
If you've stumbled upon this project and wish to contribute, please
[let me know](mailto:alister@different.com)

## Credits
* [Tamaspiros's Auto-create script](https://github.com/tamaspiros/auto-create)
