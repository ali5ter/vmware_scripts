#!/usr/bin/env bash
# @file vke_authentication.sh
# Authenticate with VMware Container Engine service using account credentials
# @author Alister Lewis-Bowen <alister@lewis-bowen.org>

set -e

source "$PWD/vke_env.sh"

## Authentication state held in ~/vke-cli/vke-config but can't find
## a way to determine if I have an exired session, so just login in each time

erun vke account login -t "$CSP_ORG_ID" -r "$TOKEN"

CUSER=$(vke -o json account show | jq -r '.sub')

# Show groups your user is a member of ---------------------------------------

heading "Groups user $CUSER belongs to"
vke -o json account show | jq -r '.groups[]' | cut -d'\' -f2

# navigate to correct scope --------------------------------------------------

heading 'Navigate to correct project scope'
erun vke folder set $(vke --output json folder list | jq -r '.items[] | .name' | grep -i "$FOLDER_REGEX")
erun vke project set $(vke --output json project list | jq -r '.items[] | .name' | grep -i "$PROJECT_REGEX")