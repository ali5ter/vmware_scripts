# Tanzu Mission Control scripts
These are bash scripts written to explore the [VMware Tanzu Mission Control](https://tanzu.vmware.com/mission-control) (TMC) CLI.

## TMC CLI binary
If you have access to TMC, then you can download the binary from the SaaS GUI. However, as a conveniece, a [download_tmc](download_tmc) script is provided here that uses the TMC API to know where to download the CLI binary.

## Environment
The [tmc_env.sh](tmc_env.sh) script can be sourced to provide the variables and some helper functions to help work with the TMC CLI (and API). All configuration can be modified in [tmc_env.sh](tmc_env.sh).

Some helper functions that I find useful:
| Function Name | Use |
| :------- | ------- |
| set_up | checks for an existing login context and adds one if you want it |
| context_detail | instead of outputting yaml for the current context, this presents a formatted summary |
| start_local_cluster | stands up a local k8s kind cluster if you don't already have one (requires docker) |
| attach_local_cluster | uses the TMC CLI to bring your local k8s cluster under management |
| deploy_application | asks your local k8s cluster to stand up a test app [(name-brainstormulator)](https://github.com/ali5ter/name-brainstormulator) |
| clean_up | detaches and removes your local k8s cluster |

## Scripts
Current list of bash scripts and what they do:
| Script | Use |
| :------- | ------- |
| [playground](playground) | general scratchpad script I use to play with the CLI when assembling commands to acheive an outcome |
| [stand_up](stand_up) | stand up a local k8s cluster and attach it to TMC |
| [tear_down](tear_down) | delete the local k8s cluster and detach it from TMC |
| [manage_namespace](manage_namespace) | deploy a test app on a local k8s cluster and attach its namespace to TMC |
| [run_inspection](run_inspection) | run a conformance inspection on a local k8s cluster |

## TMC shell prompt
I wrote a [Bash shell prompt (tmc-prompt)](https://github.com/ali5ter/tmc-prompt) to make the TMC context, management cluster and provisioner visible.

## Other Tanzu Mission Control CLI stuff
You can use [the tmctx, tmcmc and tmcp utilites](https://github.com/ali5ter/tmcctx) to help switch between TMC CLI contexts, management clusters and provisioners.

Also, if you're at all interested in CLI taxonomy, check out [cli_taxo](https://github.com/ali5ter/cli_taxo).