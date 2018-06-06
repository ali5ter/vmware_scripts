#!/usr/bin/env bash
# @file create_completion.sh
# Create a bash completion script for vke using cli_taxo
# @author Alister Lewis-Bowen <alister@lewis-bowen.org>

set -e

DIR="$PWD"

## set up cli_taxo
cd ~/tmp
mkdir -p cli_taxo
cd cli_taxo
curl -O https://raw.githubusercontent.com/ali5ter/cli_taxo/master/cli_taxo.py
curl -O https://raw.githubusercontent.com/ali5ter/cli_taxo/master/bash_completion.tmpl
curl -O https://raw.githubusercontent.com/ali5ter/cli_taxo/master/requirements.txt
pip install -r requirements.txt
chmod 755 cli_taxo.py

## generate bash completion script and move into place
./cli_taxo.py vke \
    --commands-token '^COMMANDS:$' \
    --commands-filter '^\s\s\s\s\s(?!-)(\S[^,\s]+)' \
    --options-token 'OPTIONS:$' \
    --options-filter '^\s\s\s(-\S[^,\s]+)|\s(-\S[^,\s]+)\s\s' \
    -o bash -O > "$DIR/vke_bash_completion.sh"

cd "$PWD"
