# VMware Kubernetes Engine scripts
Scripts used with VMware Kubernetes Engine (VKE).

## Configuration
Edit the [vke_config.sh](vke_config.sh) script to reflect your credentials and
VKE preferences.

## Pre-requisites
* All scripts use the VMware Kubernetes Engine CLI command, `vke`. This will be 
downloaded automatically if you don't already have it.
* [jq](https://stedolan.github.io/jq/download/) is used to parse JSON responses from `vke`.
* [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/#install-kubectl-binary-via-curl) is used to communicate to K8s deployed by the VMware Kubernetes Engine service.
* [helm](https://docs.helm.sh/using_helm/#installing-helm) is used in scripts that deploy K8s applications.

## Bash shell
[vke_bash_completion.sh](vke_bash_completion.sh) provides tab completion for
VKE cli. It is generated using [create_completion](create_completion).
Source this from your `.bash_profile` or, to use in your current shell, run 
`source vke_bash_completion.sh`

[vke_bash_prompt.sh](vke_bash_prompt.sh) adds a VKE prompt to your `PS1`.
Source this script from your `.bash_profile` and, in a new shell, enter
`vke_prompt on` to display the VKE prompt. Remove the VKE prompt by entering
`vke_prompt off`.

## Scripts
[vke_populate](vke_populate) populates a VKE project with a smart cluster with
some namespaces. The cluster name will contain a prefix configured in
[vke_config.sh](vke_config.sh)

[vke_cluster_auth](vke_cluster_auth) lists your smart clusters and allows you
to select which one to create a context for. This is useful when switching
between smart clusters.

[vke_cleanup](vke_cleanup) will look for smart clusters using the configured
prefix and remove them.

[vke_auth](vke_auth) simply authenticates using your VKE account and navigates
to the VKE folder and project configured in [vke_config.sh](vke_config.sh)

[vke_deploy_guestbook](vke_deploy_guestbook) automates the 
deployment of the google sample app, [guestbook](https://kubernetes.io/docs/tutorials/stateless-application/guestbook/), to the current K8s context.

[vke_deploy_wordpress.](vke_deploy_wordpress) uses helm to deploy a stable 
version of wordpress to the current K8s context.

