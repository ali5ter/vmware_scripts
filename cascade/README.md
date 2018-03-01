# Cascade scripts
Scripts used with Cascade M3

## Configuration
Edit the [cascade_config.sh](cascade_config.sh) script to reflect your
credentials.

## Pre-requisites
* All scripts use the Cascade CLI command, `cascade`. This will be 
downloaded automatically if you don't already have it.
* [jq](https://stedolan.github.io/jq/download/) is used to parse JSON responses from `cascade`.
* [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/#install-kubectl-binary-via-curl) is used to communicate to K8s deployed by the Cascade service.
* [helm](https://docs.helm.sh/using_helm/#installing-helm) is used in scripts that deploy K8s applications.

## Usage
The [cascade_populate.sh](cascade_populate.sh) script cleans a Cascade 
Project, then re-populates it with a Smart Cluster with some Namespaces.

The other scripts are used by the [cascade_populate.sh](cascade_populate.sh) 
script but can be used independently.

The [cascade_cluster_auth.sh](cascade_cluster_auth.sh) script is a utility to 
generate a kube configuration file for an existing Smart Cluster. This is 
useful when you want to re-access an existing Smart Cluster and manage the 
K8s cluster using kubectl

The [cascade_deploy_wordpress.sh](cascade_deploy_wordpress.sh) script uses 
helm to deploy a stable version of wordpress to the current K8s context.