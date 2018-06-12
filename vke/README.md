# VMware Kubernetes Engine scripts
Scripts used with VMware Kubernetes Engine.

## Configuration
Edit the [vke_config.sh](vke_config.sh) script to reflect your credentials.

## Pre-requisites
* All scripts use the VMware Kubernetes Engine CLI command, `vke`. This will be 
downloaded automatically if you don't already have it.
* [jq](https://stedolan.github.io/jq/download/) is used to parse JSON responses from `vke`.
* [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/#install-kubectl-binary-via-curl) is used to communicate to K8s deployed by the VMware Kubernetes Engine service.
* [helm](https://docs.helm.sh/using_helm/#installing-helm) is used in scripts that deploy K8s applications.

## Usage
The [vke_populate.sh](vke_populate.sh) script cleans a VMware Kubernetes Engine 
Project, then re-populates it with a Smart Cluster with some Namespaces.

The other scripts are used by the [vke_populate.sh](vke_populate.sh) 
script but can be used independently.

The [vke_cluster_auth.sh](vke_cluster_auth.sh) script is a utility to 
generate a kube configuration file for an existing Smart Cluster. This is 
useful when you want to re-access an existing Smart Cluster and manage the 
K8s cluster using kubectl

The [vke_deploy_guestbook.sh](vke_deploy_guestbook.sh) script automates the 
deployment of the google sample app, [guestbook](https://kubernetes.io/docs/tutorials/stateless-application/guestbook/), to the current K8s context.

The [vke_deploy_wordpress.sh](vke_deploy_wordpress.sh) script uses 
helm to deploy a stable version of wordpress to the current K8s context.

The [vke_bash_completion.sh](vke_bash_completion.sh) script is generated using [cli_taxo](https://github.com/ali5ter/cli_taxo) using the wrapper script [create_completion.sh](create_completion.sh).
