#!/usr/bin/env bash
# @file vke_bash_prompt
# Add VKE prompt to $PS1...
# 1. Source this file from your .bash_profile 
# 2. In a new shell enter `vke_prompt on`
# Turn off by entering `vke_prompt off`
# @author Alister Lewis-Bowen <alister@lewis-bowen.org>

_vke_set_evars() {
    local colors=( BLACK RED GREEN YELLOW BLUE MAGENTA CYAN WHITE )
    for (( i=0; i<${#colors[@]}; i++ )); do
        export VKE_${colors[${i}]}="$(tput setaf ${i})"
        export VKE_B${colors[${i}]}="$(tput setab ${i})"
    done
    export VKE_BOLD="$(tput bold)"
    export VKE_RESET="$(tput sgr0)"
    export VKE_PROMPT=''
}

_vke_prompt_user() {
    vke -o json account show | jq -r '.sub'
}

_vke_prompt_tenant() {
    vke -o json account show | jq -r '.tenant' | cut -c1-8
}

_vke_location() {
    local folder=$(vke -o json folder get | jq -r .Name 2>/dev/null || echo '')
    local project=$(vke -o json project get | jq -r .Name 2>/dev/null || echo '')
    local _location=''
    [[ -z ${folder} ]] || _location+="📁 ${folder}"
    [[ -z ${project} ]] || {
        _location+=" 〉🗄   ${project}"
        [[ "$VKE_PROMPT_CONTEXT_ENABLED" == 'on' ]] && {
            local cluster=$(kubectl config current-context 2>/dev/null | sed 's/-context//' || echo '')
            [[ -z ${cluster} ]] || _location+=" 〉📦 ${cluster}"
        }
    }
    echo "${_location}"
}

_vke_bash_prompt() {
    [[ "$VKE_PROMPT_ENABLED" == 'on' ]] && {
        VKE_PROMPT="${VKE_WHITE}${VKE_BOLD}${VKE_BGREEN} VKE ${VKE_RESET}${VKE_WHITE}"
        VKE_PROMPT+="${VKE_BCYAN} Usr:$(_vke_prompt_user) Org:$(_vke_prompt_tenant) "
        VKE_PROMPT+="${VKE_BBLUE} $(_vke_location)  "
        VKE_PROMPT+="${VKE_RESET}"
        echo "${VKE_PROMPT}"
    }
}

vke_prompt() {
    export VKE_PROMPT_ENABLED="$1"
    export VKE_PROMPT_CONTEXT_ENABLED='on'
    [ "$VKE_PROMPT_ENABLED" == 'on' ] && {
        _vke_set_evars
        PROMPT_COMMAND="_vke_bash_prompt; ${PROMPT_COMMAND:-}"
    }
}