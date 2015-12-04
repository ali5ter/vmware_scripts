# VMware ESXi scripts

Scripts used in conjunction with [VMware ESXi](https://www.vmware.com/products/vsphere--hypervisor).

Tested for installations of: 
ESXi 5.x
ESXi 6.x

**These scripts often assume that you have [enabled SSH and ESXi Shell](http://kb.vmware.com/selfservice/microsites/search.do?language=en_US&cmd=displayKC&externalId=2004746)
on the ESXi host.**

## Create a virtual machine
**The [create_esxi_vm.sh](create_esxi_vm.sh) script allows you to create a virtual 
machine from the command line instead of through one of the VMware UIs.**

Thi script generates the files needed to create a virtual machine and register 
it with the ESXi system. The the [default.vmx](default.vmx) file provides a
template specification for the virtual machine.

*It has been used to conveniently stand up fresh Ubuntu Server VMs using [ISOs
created for unattended installation and configured using a post installation
script](alister/ubuntu_install_tools/).*

### VM creation from the ESXi cmdl
Log into the ESXi server and download the script like this

    wget http://gitlab.different.com/alister/ubuntu_install_tools/raw/master/create_esxi_vm.sh && chmod 755 create_esxi_vm.sh

Create a virtual machine using the vCPU, memory and storage defaults using one
of the installation ISOs like this

    ./create_esxi_vm.sh -n server_01 -i /vmfs/volumes/datastore1/ISOs/ubuntu-14.04.3-server-amd64-unattended.iso

For help about changing the defaults run

    ./create_esxi_vm.sh -h

Once complete, the virtual machine will automically power on.

### Remote VM creation
[documentation to come]

## Contribution                                                                 
If you've stumbled upon this project and wish to contribute, please             
[let me know](mailto:alister@different.com)