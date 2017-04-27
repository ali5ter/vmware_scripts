# Creating an ESXi bootable flash drive

Download the ESXi iso. I got mine from [ESXi 6.0 build# 3073146](https://buildweb.eng.vmware.com/ob/3073146/)

If this flash drive has been used for other things we need to erase all partitions and reformat them. So, open Disk Utility, identfy the USB flash drive **drive** and erase it. The Erase dialog allows you to name and format a new volume. Reformat using *MS-DOS (FAT)* and type *Master Boot Record*.

If Disk Utility compaines about not being able to erase the volume, try

	sudo fdisk -i -a dos /dev/diskX
	
(assumes you know what the device name is)

In the OSX Terminal, run 

	diskutil list

Look for the name you just gave the flash drive volume formatted to *DOS_FAT_32*. Note the identifier, e.g. */dev/disk4*

Unmount the flash drive disk using

	diskutil unmountDisk /dev/diskX

Enter `fdisk` interactive mode using

	sudo fdisk -e /dev/diskX
	
At the prompt, type the following commands to flag the first partition as active and bootable and write the master boot record to it

	fdisk:*1> f 1
	Partition 1 marked active.
	fdisk:*1> write
	Writing MBR at offset 0.
	fdisk: 1> quit

The *write* instruction appears to remount the drive but if it didn't, use

	diskutil mountDisk /dev/diskX
	
Now the flash drive is ready, we prepare the content.

Mount the iso you downloaded earlier, e.g.

	open VMware-VMvisor-Installer-6.0.0-3073146.x86_64.iso
	
Copy over the contents of the mounted ISO into the mounted flash drive, either from the command line or using Finder.

Rename *ISOLINUX.CFG* file on the flash drive to *SYSLINUX.CFG*, e.g.

	cd /Volumes/[name_of_flash_drive/
	mv ISOLINUX.CFG SYSLINUX.CFG

Edit the *SYSLINUX.CFG* file on the flash drive like this

	vi SYSLINUX.CFG
	
Add `-p 1` to the end of the line `APPEND -x coot.cfg` to tell the system which partition to boot from.

Eject the drive and plug it into the target system (in my case, a Mac Mini), then boot that system (for a Mac Mini, holding down Alt/Opt) and select the USB flash drive as the boot device.


## Reference
* [ESXi 6.0 build# 3073146](https://buildweb.eng.vmware.com/ob/3073146/)
* [Format a USB Flash Drive to Boot the ESXi Installation or Upgrade](http://pubs.vmware.com/vsphere-60/index.jsp#com.vmware.vsphere.upgrade.doc/GUID-33C3E7D5-20D0-4F84-B2E3-5CD33D32EAA8.html?resultof=%2522%2566%256f%2572%256d%2561%2574%2522%2520%2522%2555%2553%2542%2522%2520%2522%2575%2573%2562%2522%2520)
