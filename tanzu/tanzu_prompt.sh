#!/usr/bin/env bash
# @file tanzu_prompt.sh
# Add current context(s) to prompt
# @author Alister Lewis-Bowen <bowena@vmware.com>
#
# REQUIREMENTS
# - tanzu cli
# - yq
#
# INSTALLATION
# - Source tanzu_prompt.sh, e.g `. /path/to/tanzu_prompt.sh.`
# - Toggle visibility of the prompt with `/path/to/tanzu_prompt.sh on|off`
#   - You can also source this script from your Bash runcom, e.g. ~/bashrc to
#     persist the prompt across bash sessions and add any of the configuration
#     overides explained below.
# - Configure your preferred prompt framework to use `tanzu_prompt`
#   - for example, for a straight forward bash prompt, 
#     `export PROMPT_COMMAND="tanzu_prompt;  \${PROMPT_COMMAND:-}"`
#   - for Starship, add the folliwng to the config...
# [custom.tanzu]
# description = "Display the current tanzu contexts"
# command = ". $TANZU_PROMPT_SCRIPT_DIR/tanzu_prompt.sh; tanzu_prompt"
# when= "command -v tanzu 1>/dev/null 2>&1"
# disabled = false
#
# CONFIGURATION
# - TANZU_PROMPT_FORMAT - the format of the prompt, default is '[TANZU#CONTEXT_LIST#]'
# - TANZU_PROMPT_CONTEXT_LIST_FORMAT - the format of each context in the list, default is ' #CONTEXT#'

[[ -n $DEBUG ]] && set -x

_tanzu_init() {
    # shellcheck disable=SC2155
    export TANZU_PROMPT_SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    export TANZU_CONTEXTS=''
    export TANZU_PROMPT=''
    export TANZU_PROMPT_FORMAT='〄 #CONTEXT_LIST#'
    export TANZU_PROMPT_CONTEXT_LIST_FORMAT=' #CONTEXT#'
    export TANZU_PROMPT_ENABLED='on'
}
[[ -z "$TANZU_PROMPT_SCRIPT_DIR" || "$1" == 'init' ]] && _tanzu_init

_tanzu_fetch_contexts() {
  # tanzu context list --current -o json | jq -r .[].name
  tanzu config get | yq -r '.currentContext' | tr -d ' '
}

_tanzu_build_prompt() {
    local context contexts
    # shellcheck disable=SC2155
    export TANZU_CONTEXTS="$(_tanzu_fetch_contexts)"
    if [ -n "$TANZU_CONTEXTS" ]; then
        for context in $TANZU_CONTEXTS; do
            contexts="$contexts ${TANZU_PROMPT_CONTEXT_LIST_FORMAT//#CONTEXT#/$context}"
        done
        contexts="$(echo "$contexts"|xargs)"
        export TANZU_PROMPT="${TANZU_PROMPT_FORMAT//#CONTEXT_LIST#/$contexts}"
        [[ "$TANZU_PROMPT_ENABLED" == 'on' ]] && echo -en "$TANZU_PROMPT"
    else
        return 1
    fi
}

# show or toggle the visibility of the Tanzu prompt, `tanzu_prompt on|off`
# shellcheck disable=SC2120
tanzu_prompt() { 
    local toggle="${1:-}"
    if [[ -z "$toggle" ]]; then 
        _tanzu_build_prompt
    else
        export TANZU_PROMPT_ENABLED="$toggle"; 
    fi
}

# Return prompt if this script is called directly
[ "${BASH_SOURCE[0]}" -ef "$0" ] && {
    tanzu_prompt
    [[ $(tty) =~ "not a tty" ]] || echo
}
