# Photon Controller scripts
Scripts used with Photon Controller v1.2

The [pc_populate.sh](pc_populate.sh) scripts cleans a Photon Controller (PC) instance, then re-populates it with objects to get:
1. A photonOS image for VMs and a Kubernetes image for Clusters
2. Some useful VM and disk flavors
3. A test tenant with 20,000 quota limits
4. A test project in the tenant using all the quota
5. A default subnet connected to the default project router
6. A persistant disk for the project
5. A test VM in the project
6. A test cluster for kubernetes
7. The choice of 10 more tenants with between 1 and 10 projects in them.

The other scripts are used by the [pc_populate.sh](pc_populate.sh) script but can be used independently.

The [generate_word_string.sh](generate_word_string.sh) script is purely a utility to generate placeholder text for object names and descriptions. 
