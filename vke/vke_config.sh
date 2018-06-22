#!/usr/bin/env bash
# @file vke_config.sh
# VMware Kubernetes Engine account settings
# @author Alister Lewis-Bowen <alister@lewis-bowen.org>

TARGET='https://api.vke.cloud.vmware.com'
TOKEN='8698fa83-f29f-4354-aeb9-ac6c4a44bd1d'
CSP_ORG_ID='fa2c1d78-9f00-4e30-8268-4ab81862080d'

FOLDER_REGEX='ui'
PROJECT_REGEX='ui'
REGION_REGEX='us'
CLUSTER_PREFIX='alb'
#CLUSTER_DNAME_PREFIX='alb-🦄'
CLUSTER_DNAME_PREFIX='alb'
DEPLOYMENT_PREFIX='alb'