#!/usr/bin/env bash
# @file tmc_config.sh
# VMware Tanzu Mission Control account settings and preferences
# Note that this only messes around with staging stacks 'unstable' and 'stable'
# @author Alister Lewis-Bowen <alister@lewis-bowen.org>

# CSP configuration ----------------------------------------------------------

# INSTRUCTIONS
# You will need to generate a VMware Cloud Services API Token. You do this 
# under My Account > API Tokens. Define the token for the stacks you want
# to use, e.g. stable and unstable. 
#
# After you are presented with the token, copy it, and then put it into a
# file on your OS. If you're using MacOS, you can paste the token using
#    pbpaste > ~/.config/csp-staging-token
#
# 1. Make sute the CSP_API_TOKEN variable below refers to the file you pasted
#    the token into.
# 2. The other variables in this section you can leave.

# shellcheck disable=SC2034
CSP_API_TOKEN="$(cat ~/.config/csp-staging-token)" # CSP refresh token
CSP_ENDPOINT_HOSTNAME='console-stg.cloud.vmware.com' # staging
CSP_ENDPOINT="https://${CSP_ENDPOINT_HOSTNAME}/csp/gateway/am/api"
CSP_ACCESS_TOKEN="$(\
    curl -sSX POST "${CSP_ENDPOINT}/auth/api-tokens/authorize\?refresh_token=${CSP_API_TOKEN}" |\
    jq -r .access_token)"

# TMC configuration ----------------------------------------------------------

# INSTRUCTIONS
# Most of the variables in this section you can leave alone. Focus on the those
# that personalize the resources these scripts work with.
#
# 1. Use TMC_CLUSTER_NAME to prefix the name of the ks8 cluster you create locally
#    and those that you tell TMC to manage, e.g. <your-initials>-${TMC_PROVIDER}.
#    Keep the '${TMC_PROVIDER}' part because it will differentiate between your
#    local clsuter and any stood up on a cloud.
# 2. The TMC_CLUSTER_GROUP variable names the TMC cluster group the scripts will
#    create, or look for, inside which your TMC managed clusters will appear.
# 3. Use TMC_DESCRIPTION to help identify stuff created by you.

TMC_KUBECONFIG_STORE_PREFIX="$HOME/.config/tmc_kubeconfig_"
TMC_STACK="${1:-unstable}"  # unstable|stable
TMC_CONTEXT="tmc-${TMC_STACK}"
TMC_API_ENDPOINT_HOSTNAME="tmc-users-${TMC_STACK}.tmc-dev.cloud.vmware.com"
TMC_API_ENDPOINT="https://${TMC_API_ENDPOINT_HOSTNAME}"
TMC_MNGMT_CLUSTER='attached'
TMC_PROVISIONER='attached'
TMC_LOG_LEVEL='debug'
TMC_PROVIDER='local'
TMC_CLUSTER_NAME="<your-initials>-dev-${TMC_PROVIDER}"
TMC_CLUSTER_GROUP='<your-initials>-test'
TMC_WORKSPACE='<your-initials>-test'
TMC_DESCRIPTION="<your-name> testing again. Please delete if needed."
TMC_LABELS='env=test,generatedFrom=vmware_scripts'

# AWS configuration ----------------------------------------------------------

# INSTRUCTIONS
# This section contains the configuration contained within your AWS Account
# and is used when provisioning an EC2 based k8s cluster that TMC can manage
#
# Note that you will need to have created an 'aws-hosted' provisioner and
# account in TMC first and an EC2 SSH Keypair.
#
# **If you don't intend to stand up an AWS-EC2 k8s cluster using these scripts
# and just work with a local k8s cluster, then please ignore these variables**
#
# 1. The name of the EC2 SSH Keypair should be the value of the AWS_SSH_KEY
#    variable. If you've set up the AWS CLI, you can list your keypair names
#    using the command
#       aws ec2 describe-key-pairs | jq -r '.KeyPairs[].KeyName'
# 2. The AWS_REGION variable contains the name of the default reqion for your
#    AWS Account. Again, if you've set up the AWS CLI, use the following
#    command show the default region
#       aws configure list | grep region | awk '{print $2}'
# 3. The other variables in this section you can leave.

AWS_SSH_KEY="alb-sshkey-test"
AWS_REGION="us-east-2"
AWS_AZ="${AWS_REGION}a"
AWS_K8S_VERSION="1.20.11-1-amazon2"