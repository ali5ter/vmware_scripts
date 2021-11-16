#!/usr/bin/env bash
# @file tmc_config.sh
# VMware Tanzu Mission Control account settings and preferences
# Note that this only messes around with staging stacks 'unstable' and 'stable'
# @author Alister Lewis-Bowen <alister@lewis-bowen.org>

# shellcheck disable=SC2034
CSP_API_TOKEN="$(cat ~/.config/csp-staging-token)" # CSP refresh token
CSP_ENDPOINT_HOSTNAME='console-stg.cloud.vmware.com' # staging
CSP_ENDPOINT="https://${CSP_ENDPOINT_HOSTNAME}/csp/gateway/am/api"
CSP_ACCESS_TOKEN="$(\
    curl -sSX POST "${CSP_ENDPOINT}/auth/api-tokens/authorize\?refresh_token\=${CSP_API_TOKEN}" |\
    jq -r .access_token)"

TMC_STACK="${1:-unstable}"  # unstable|stable
TMC_CONTEXT="tmc-${TMC_STACK}"
TMC_API_ENDPOINT_HOSTNAME="tmc-users-${TMC_STACK}.tmc-dev.cloud.vmware.com"
TMC_API_ENDPOINT="https://${TMC_API_ENDPOINT_HOSTNAME}"
TMC_MNGMT_CLUSTER='attached'
TMC_PROVISIONER='attached'
TMC_LOG_LEVEL='debug'
TMC_CLUSTER_NAME='alb-dev-local'
TMC_CLUSTER_GROUP='alb-test'
TMC_WORKSPACE='alb-test'
TMC_DESCRIPTION="🦄  Alister testing again. Please delete if needed."
TMC_LABELS='env=test,generatedFrom=vmware_scripts'
# TMC_UPDATE_DATE="$HOME/.config/.tmc_last_update"