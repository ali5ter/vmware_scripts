# VMware Cloud PKS scripts
Scripts used with VMware Cloud PKS (VCP).

## Configuration
Copy the [vcp_config.sh.sample](vcp_config.sh.sample) file to `vcp_config.sh` and edit it to reflect your credentials and VKE preferences.

## Pre-requisites
* All scripts use the VMware Cloud PKS CLI command, `vcp`. This will be downloaded automatically if you don't already have it.
* [jq](https://stedolan.github.io/jq/download/) is used to parse JSON responses from `vcp`.
* [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/#install-kubectl-binary-via-curl) is used to communicate to K8s deployed by the VMware Kubernetes Engine service.
* [helm](https://docs.helm.sh/using_helm/#installing-helm) is used in scripts that deploy K8s applications.

## VCP environment
[vcp_env.sh](vcp_env.sh) checks for the pre-requisites stated above but also provides some helper functions:
* [vcp_cli_url](https://github.com/ali5ter/vmware_scripts/blob/8e662d6f5f5acf195b5633e94dd50113193267fa/vcp/vcp_env.sh#L16) returns the URL for the VCP cli based on the OS you're running on.
* [vcp_cli_check_version](https://github.com/ali5ter/vmware_scripts/blob/8e662d6f5f5acf195b5633e94dd50113193267fa/vcp/vcp_env.sh#L32) checks if there's a newer version of the VCP cli available.
* [vcp_get_admin_for_object](https://github.com/ali5ter/vmware_scripts/blob/8e662d6f5f5acf195b5633e94dd50113193267fa/vcp/vcp_env.sh#L89) parses the direct and inherited access policies for a VCP folder, project, smart cluster or namespace to extract the admnistrator identites for that object.

## Automation scripts
[vcp_populate](vcp_populate) populates a VCP project with a smart cluster with
some namespaces. The cluster name will contain a prefix configured in
[vcp_config.sh](vcp_config.sh)

[vcp_cluster_auth](vcp_cluster_auth) lists your smart clusters and allows you
to select which one to create a context for. This is useful when switching
between smart clusters.

[vcp_cleanup](vcp_cleanup) will look for smart clusters using the configured
prefix and remove them.

[vcp_auth](vcp_auth) simply authenticates using your VCP account.

[vcp_info](vcp_info) lists useful information about your VCP account and location in the taxonomy.

[vcp_deploy_guestbook](vcp_deploy_guestbook) automates the 
deployment of the google sample app, [guestbook](https://kubernetes.io/docs/tutorials/stateless-application/guestbook/), to the current K8s context.

[vcp_deploy_wordpress.](vcp_deploy_wordpress) uses helm to deploy a stable 
version of wordpress to the current K8s context.

## Other VCP utilities
You may have use for some other VCP projects:
* [Install VCP cli using homebrew](https://github.com/ali5ter/homebrew-vcp-cli)
* [VCP cli bash or zsh completion](https://github.com/ali5ter/vcp-completion)
* [A bash VCP prompt](https://github.com/ali5ter/vcp-prompt)
* [Extended VCP cli functionality](https://github.com/ali5ter/vcp-cli-extended)