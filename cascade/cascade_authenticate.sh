#!/usr/bin/env bash
# @file cascade_authentication.sh
# Authenticate with Cascade service using account credentials
# @author Alister Lewis-Bowen <alister@lewis-bowen.org>

set -e

source "$PWD/cascade_config.sh"

## Authentication state held in ~/cascade-cli/cascade-config but can't find
## a way to determine if I have an exired session, so just login in each time

cascade target set "$API_URL"
cascade target login --i csp -t "$CSP_ORG_ID" -r "$TOKEN"