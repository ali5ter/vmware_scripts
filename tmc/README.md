# Tanzu Mission Control scripts
These are bash scripts written to explore the [VMware Tanzu Mission Control](https://tanzu.vmware.com/mission-control) (TMC) CLI.

## TMC CLI binary
If you have access to TMC, then you can download the binary from the SaaS GUI. However, as a conveniece, a [download_tmc](download_tmc) script is provided here that uses the TMC API to know where to download the CLI binary.

## Environment
The [tmc_env.sh](tmc_env.sh) script can be sourced to provide the variables and some helper functions to help work with the TMC CLI (and API). 

All configuration can be modified in [tmc_config.sh](tmc_config.sh). Make sure to generate an API Token form your VMware Cloud account settings for the TMC service(s) you intent to run these scripts against. The [tmc_config.sh](tmc_config.sh) currently expects to see this token in a local file at `~/.config/csp-staging-token`.

These scripts rely on some tools as prerequisites: the TMC CLI (obviously), kind, kubectl, jq and fzf.
If you're using macOS, other than TMC, these are all available via [homebrew](https://brew.sh)...
  
`brew install kind kubectl jq fzf`

Using `kind` to stand up a kubernetes cluster assumes that docker is present. There are different options to do this, but if you're using macOS, a good option is to install [Docker Desktop](https://www.docker.com/products/docker-desktop) using [homebrew](https://brew.sh)...

`brew install --cask docker`

Some helper functions that the [tmc_env.sh](tmc_env.sh) script provides which you might find useful:
| Function Name | Use |
| :------- | ------- |
| set_up \[unstable\|stable\] | checks for an existing login context and adds one if you want it... if you don't pass the stack name then it will default to 'unstable' |
| context_detail | instead of outputting yaml for the current context, this presents a formatted summary |
| start_local_cluster | stands up a local k8s kind cluster if you don't already have one (requires docker) |
| attach_local_cluster | uses the TMC CLI to bring your local k8s cluster under management |
| set_cluster | select a TMC manager k8s cluster to work with |
| deploy_application | asks your local k8s cluster to stand up a test app [(name-brainstormulator)](https://github.com/ali5ter/name-brainstormulator) |
| remove_tmc_managed_cluster | delete/detach the current TMC managed cluster |
| clean_up | deleted/detaches TMC managed clusters and removes your local k8s cluster |
| get_aws_arn | retrieve the TMC lifecycle ARN in your AWS account |

These scripts will store any kubeconfig files that TMC provides under `~/.config` should you need them when running `kubectl` against clusters managed by TMC.

## Scripts
Current list of bash scripts and what they do:
| Script | Use |
| :------- | ------- |
| [stand_up](stand_up) \[unstable\|stable\] | stand up a k8s cluster that TMC can manage... if you don't pass the stack name then it will default to 'unstable' |
| [tear_down](tear_down) \[unstable\|stable\] | choose which TMC managed cluster to delete/detach and delete the local k8s cluster |
| [manage_namespace](manage_namespace) \[unstable\|stable\] | deploy a test app on a TMC managed k8s cluster and attach its namespace to TMC |
| [run_inspection](run_inspection) \[unstable\|stable\]| run a conformance inspection on a TMC managed k8s cluster |
| [data_protection](data_protection) \[unstable\|stable\]| set up data protection on a TMC managed k8s cluster |
| [playground](playground) \[unstable\|stable\] | general scratchpad script I use to play with the CLI when assembling commands to acheive an outcome |
| [context_detail](context_detail) | display the TMC context detail, any TMC kubeconfigs and local kubectl contexts |
| [get_arn](get_arn) | display the TCM lifecycle ARN in your AWS account |
| [stand_up_using_terraform](stand_up_using_terraform) | stand up the clsuter group, workspace and attach a local cluster using the [TMC Terraform Provider](https://registry.terraform.io/providers/vmware/tanzu-mission-control/latest) |

## TMC shell prompt
I wrote a [Bash shell prompt (tmc-prompt)](https://github.com/ali5ter/tmc-prompt) to make the TMC context, management cluster and provisioner visible.

## Other Tanzu Mission Control CLI stuff
You can use [the tmctx, tmcmc and tmcp utilites](https://github.com/ali5ter/tmcctx) to help switch between TMC CLI contexts, management clusters and provisioners.

Also, if you're at all interested in CLI taxonomy, check out [cli_taxo](https://github.com/ali5ter/cli_taxo).
