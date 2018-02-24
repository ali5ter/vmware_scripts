#!/usr/bin/env bash

set -e

source "$PWD/cascade_config.sh"

type cascade &> /dev/null || {
    echo "Please install cascade CLI by downloading from one of these URLs"
    curl -s "$UI_URL"v1/cli | jq '.latest' | grep -v [{}]
    echo "Add execute permissions and move into your path"
    exit 1
}
cascade -v

## No real way to determine if I have an exired session, so just login in

cascade target set "$API_URL"
cascade target login --i csp -t "$CSP_ORG_ID" -r "$TOKEN"