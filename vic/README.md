# vSphere Integrated Containers scripts
Scripts used with [vSphere Integrated Containers](https://www.vmware.com/products/vsphere/integrated-containers.html)

The [vic_populate.sh](vic_populate.sh) script cleans a VIC enable vCenter Server instance, then re-populates it with Virtual Container Hosts

The other scripts are used by the [vic_populate.sh](vic_populate.sh) script but can be used independently.

For example, [vic_setup.sh](vic_setup.sh) conveniently downloads the vic-machine binary, prepares the VIC environment variables, configures any firewall rules for your VC and provides bash completion for vic-machine.