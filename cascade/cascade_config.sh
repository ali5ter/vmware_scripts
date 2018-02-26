#!/usr/bin/env bash
# @file cascade_config.sh
# Cascade account settings and common helper functions
# @author Alister Lewis-Bowen <alister@lewis-bowen.org>

UI_URL='https://cascade.cloud.vmware.com'
API_URL='https://api.cascade-cloud.com'
USER='bowena@vmware.com'
TOKEN='8698fa83-f29f-4354-aeb9-ac6c4a44bd1d'
CSP_ORG_ID='fa2c1d78-9f00-4e30-8268-4ab81862080d'

FOLDER_REGEX='ui'
PROJECT_REGEX='ui'
REGION_REGEX='us'
CLUSTER_PREFIX='alb'

# helper functions -----------------------------------------------------------

get_cli() {
    echo "Please install cascade CLI by downloading from one of these URLs"
    curl -s "$UI_URL"v1/cli | jq '.latest' | grep -v [{}]
    echo "Add execute permissions and move into your path"
}

type cascade &> /dev/null || {
    get_cli
    exit 1
}

VERSION_FILE=~/.cascade_version
if [ -f "$VERSION_FILE" ]; then
    [ "$(cascade -v)" != "$(cat $VERSION_FILE)" ] && {
        echo "You have a different version of the cascade CLI"
        get_cli
        exit 1
    }
else
    touch "$VERSION_FILE" && cascade -v > "$VERSION_FILE"
fi

heading() {
    printf '=%.0s' {1..79}
    echo -e "\n$1" | fold -s -w 79
    printf '=%.0s' {1..79}
    echo
}
