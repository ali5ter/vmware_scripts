#!/usr/bin/env bash

UI_URL='https://cascade.cloud.vmware.com'
API_URL='https://api.cascade-cloud.com'
USER='bowena@vmware.com'
TOKEN='8698fa83-f29f-4354-aeb9-ac6c4a44bd1d'
CSP_ORG_ID='fa2c1d78-9f00-4e30-8268-4ab81862080d'

FOLDER_REGEX='ui'
PROJECT_REGEX='ui'
REGION_REGEX='us'
CLUSTER_PREFIX='alb'

heading() {
    printf '=%.0s' {1..79}
    echo -e "\n$1" | fold -s -w 79
    printf '=%.0s' {1..79}
    echo
}