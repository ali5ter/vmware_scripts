#!/usr/bin/env bash
# @file cascade_authentication.sh
# Authenticate with Cascade service using account credentials
# @author Alister Lewis-Bowen <alister@lewis-bowen.org>

set -e

source "$PWD/cascade_env.sh"

## Authentication state held in ~/cascade-cli/cascade-config but can't find
## a way to determine if I have an exired session, so just login in each time

cascade target set "$API_URL"
cascade target login --i csp -t "$CSP_ORG_ID" -r "$TOKEN"

cascade tenant get

## Unable to get the user identity I'm signed in as

# navigate to correct scope --------------------------------------------------

## Now that output is tabulated with lots more visual chars, it's easier to
## output in json and use jq to extract attributes needed

## Notice that some json responses use an anonymous array and some use an array
## called 'items'

heading 'Navigate to correct project scope'
cascade folder set $(cascade --output json folder list | jq -r '.items[] | .name' | grep -i "$FOLDER_REGEX")
cascade project set $(cascade --output json project list | jq -r '.[] | .name' | grep -i "$PROJECT_REGEX")