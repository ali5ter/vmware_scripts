#!/usr/bin/env bash
# @file cascade_authentication.sh
# Authenticate with Cascade service using account credentials
# @author Alister Lewis-Bowen <alister@lewis-bowen.org>

set -e

source "$PWD/cascade_env.sh"

## Authentication state held in ~/cascade-cli/cascade-config but can't find
## a way to determine if I have an exired session, so just login in each time

erun cascade target login --i csp -t "$CSP_ORG_ID" -r "$TOKEN"

CUSER=$(cascade -o json account show | jq -r '.sub')
CUSER_ID=$(cascade -o json user show $CUSER | jq -r '.id')

# Show groups your user is a member of ---------------------------------------

heading "Groups user $CUSER belongs to"
cascade -o json account show | jq -r '.groups[]' | cut -d'\' -f2

# navigate to correct scope --------------------------------------------------

heading 'Navigate to correct project scope'
erun cascade folder set $(cascade --output json folder list | jq -r '.items[] | .name' | grep -i "$FOLDER_REGEX")
erun cascade project set $(cascade --output json project list | jq -r '.items[] | .name' | grep -i "$PROJECT_REGEX")