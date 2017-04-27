# Nested ESXi configuration

## Testing for nested capability
To test if the CPU of the machine you're using supports *Nested Virtualization* (HV) open the mob at the following location

	https://[esxi_address]/mob/?moid=ha-host&doPath=capability

and search for *nestedHVSupported*. If *true*, you can run nested 64-bit VMs.

Note: If mob is disabled, log onto the ESXi system and use the following command to enable it

	vim-cmd hostsvc/advopt/update Config.HostAgent.plugins.solo.enableMob bool true 

Note: HV is fully supported for virtual hardware version 9 or later VMs on hosts that support Intel VT-x and EPT or AMD-V and RVI.

## CPU Configuration of a new VM
Make sure to select HW version 9.

When editing the VM settings for CPU, make sure HV is enabled.

## Reference
* [How to Enable Nested ESXi & Other Hypervisors in vSphere 5.1](http://www.virtuallyghetto.com/2012/08/how-to-enable-nested-esxi-other.html)
* [ESXi 6.0 – Hardware Virtualization is not a feature of the CPU](https://devopsboy.wordpress.com/2015/04/21/hvnotafeatcpu/)