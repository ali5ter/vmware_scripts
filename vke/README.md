# VMware Kubernetes Engine scripts
Scripts used with VMware Kubernetes Engine (VKE).

## Configuration
Copy the [vke_config.sh.sample](vke_config.sh.sample) file to `vke_config.sh` and edit it to reflect your credentials and VKE preferences.

## Pre-requisites
* All scripts use the VMware Kubernetes Engine CLI command, `vke`. This will be 
downloaded automatically if you don't already have it.
* [jq](https://stedolan.github.io/jq/download/) is used to parse JSON responses from `vke`.
* [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/#install-kubectl-binary-via-curl) is used to communicate to K8s deployed by the VMware Kubernetes Engine service.
* [helm](https://docs.helm.sh/using_helm/#installing-helm) is used in scripts that deploy K8s applications.

## VKE tab completion
[vke_bash_completion.sh](vke_bash_completion.sh) provides bash tab completion
for the VKE cli. It is generated using [create_completion](create_completion).
Source this from your `.bash_profile` or, to use in your current shell, run 
`source vke_bash_completion.sh`

If you're using zsh, the following should allow this autocompletion to work:

    $ autoload bashcompinit
    $ bashcompinit
    $ source vke_bash_completion.sh

## VKE prompt
[vke_bash_prompt.sh](vke_bash_prompt.sh) adds a VKE prompt to your `PS1`.
Source this script from your `.bash_profile` and, in a new shell, enter
`vke_prompt on` to display the VKE prompt. Remove the VKE prompt by entering
`vke_prompt off`.

You can hide the K8s current context in this prompt using
`export VKE_PROMPT_CONTEXT_ENABLED='off'`. Useful if you're already using
something like [kube-ps1](https://github.com/jonmosco/kube-ps1).

## VKE environment
[vke_env.sh](vke_env.sh) checks for the pre-requisites stated above but also provides some helper functions:
* [vke_cli_url](https://github.com/ali5ter/vmware_scripts/blob/8e662d6f5f5acf195b5633e94dd50113193267fa/vke/vke_env.sh#L16) returns the URL for the VKE cli based on the OS you're running on.
* [vke_cli_check_version](https://github.com/ali5ter/vmware_scripts/blob/8e662d6f5f5acf195b5633e94dd50113193267fa/vke/vke_env.sh#L32) checks if there's a newer version of the VKE cli available.
* [vke_get_admin_for_object](https://github.com/ali5ter/vmware_scripts/blob/8e662d6f5f5acf195b5633e94dd50113193267fa/vke/vke_env.sh#L89) parses the direct and inherited access policies for a VKE folder, project, smart cluster or namespace to extract the admnistrator identites for that object.

## Automation scripts
[vke_populate](vke_populate) populates a VKE project with a smart cluster with
some namespaces. The cluster name will contain a prefix configured in
[vke_config.sh](vke_config.sh)

[vke_cluster_auth](vke_cluster_auth) lists your smart clusters and allows you
to select which one to create a context for. This is useful when switching
between smart clusters.

[vke_cleanup](vke_cleanup) will look for smart clusters using the configured
prefix and remove them.

[vke_auth](vke_auth) simply authenticates using your VKE account.

[vke_info](vke_info) lists useful information about your VKE account and location in the taxonomy.

[vke_deploy_guestbook](vke_deploy_guestbook) automates the 
deployment of the google sample app, [guestbook](https://kubernetes.io/docs/tutorials/stateless-application/guestbook/), to the current K8s context.

[vke_deploy_wordpress.](vke_deploy_wordpress) uses helm to deploy a stable 
version of wordpress to the current K8s context.

