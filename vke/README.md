# VMware Cloud PKS (formerly VKE) scripts

## Configuration
Copy the [vke_config.sh.sample](vke_config.sh.sample) file to `vke_config.sh` and edit it to reflect your credentials and Cloud PKS preferences.

## Pre-requisites
* All scripts use the Cloud PKS CLI command, `vke`. This will be 
downloaded automatically if you don't already have it.
* [jq](https://stedolan.github.io/jq/download/) is used to parse JSON responses from `vke`.
* [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/#install-kubectl-binary-via-curl) is used to communicate to K8s deployed by the Cloud PKS service.
* [helm](https://docs.helm.sh/using_helm/#installing-helm) is used in scripts that deploy K8s applications.

## Cloud PKS environment
[vke_env.sh](vke_env.sh) checks for the pre-requisites stated above but also provides some helper functions:
* [vke_cli_url](https://github.com/ali5ter/vmware_scripts/blob/8e662d6f5f5acf195b5633e94dd50113193267fa/vke/vke_env.sh#L16) returns the URL for the Cloud PKS CLI based on the OS you're running on.
* [vke_cli_check_version](https://github.com/ali5ter/vmware_scripts/blob/8e662d6f5f5acf195b5633e94dd50113193267fa/vke/vke_env.sh#L32) checks if there's a newer version of the Cloud PKS CLI available.
* [vke_get_admin_for_object](https://github.com/ali5ter/vmware_scripts/blob/8e662d6f5f5acf195b5633e94dd50113193267fa/vke/vke_env.sh#L89) parses the direct and inherited access policies for a Cloud PKS folder, project, smart cluster or namespace to extract the admnistrator identites for that object.

## Automation scripts
[vke_populate](vke_populate) populates a Cloud PKS project with a smart cluster with
some namespaces. The cluster name will contain a prefix configured in
[vke_config.sh](vke_config.sh)

[vke_cluster_auth](vke_cluster_auth) lists your smart clusters and allows you
to select which one to create a context for. This is useful when switching
between smart clusters.

[vke_cleanup](vke_cleanup) will look for smart clusters using the configured
prefix and remove them.

[vke_auth](vke_auth) simply authenticates using your Cloud PKS account.

[vke_info](vke_info) lists useful information about your Cloud PKS account and location in the taxonomy.

[vke_deploy_guestbook](vke_deploy_guestbook) automates the 
deployment of the google sample app, [guestbook](https://kubernetes.io/docs/tutorials/stateless-application/guestbook/), to the current K8s context.

[vke_deploy_wordpress.](vke_deploy_wordpress) uses helm to deploy a stable 
version of wordpress to the current K8s context.

## Other Cloud PKS utilities
You may have use for some other Cloud PKS projects:
* [Install Cloud PKS CLI using homebrew](https://github.com/ali5ter/homebrew-vke-cli)
* [Cloud PKS CLI bash or zsh completion](https://github.com/ali5ter/vke-completion)
* [A bash Cloud PKS prompt](https://github.com/ali5ter/vke-prompt)
* [Extended Cloud PKS CLI functionality](https://github.com/ali5ter/vke-cli-extended)
