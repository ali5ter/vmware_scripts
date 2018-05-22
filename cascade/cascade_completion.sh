#!/usr/bin/env bash
# Bash completion for cascade CLI command
# Generated by cli_taxo

_cascade_complete () {

    local cur="${COMP_WORDS[COMP_CWORD]}"
    local prev="${COMP_WORDS[COMP_CWORD-1]}"

    echo "${COMP_WORDS[@]}" | grep -q '-' && {
        i=0
        until echo "${COMP_WORDS[i]}" | grep -q '-' ; do ((i++)); done
        prev="${COMP_WORDS[i-1]}"
    }
    
    case "$prev" in
                rename)    cmds="--folder --project";;
        set)    cmds="--folder";;
        show)    cmds="--folder --folder --perf --folder --project --folder --project --folder --project";;
        cluster)    cmds="templates versions create show show-health list resize rename delete upgrade maintain get-kubectl-auth merge-kubectl-auth iam namespace --help";;
        export)    cmds="--output --output --output --folder --output --folder --project";;
        show-health)    cmds="--folder --project";;
        merge-kubectl-auth)    cmds="--folder --project";;
        iam)    cmds="show export import add remove --help role user group --help show export import add remove --help show export import add remove --help show export import add remove --help show export import add remove --help";;
        upgrade)    cmds="--version --folder --project";;
        group)    cmds="create delete show list member --help";;
        create)    cmds="--description --display-name --display-name --folder --name --service-level --display-name --size --container-network --region --version --template --folder --project --folder --project";;
        namespace)    cmds="create delete show list iam --help";;
        member)    cmds="add remove list --help";;
        add)    cmds="--subject --role --subject --role --subject --role --folder --subject --role --folder --project";;
        role)    cmds="list --help";;
        resize)    cmds="--folder --project";;
        import)    cmds="--input --input --input --folder --input --folder --project";;
        folder)    cmds="create delete show get set list iam --help";;
        templates)    cmds="list --help";;
        user)    cmds="show list --help";;
        tenant)    cmds="show iam --help";;
        info)    cmds="region --help";;
        account)    cmds="show login --help";;
        get-kubectl-auth)    cmds="--configfile --folder --project";;
        versions)    cmds="list --help";;
        region)    cmds="list --help";;
        list)    cmds="--folder --region --folder --project --folder --project";;
        remove)    cmds="--subject --role --subject --role --subject --role --folder --subject --role --folder --project";;
        project)    cmds="create delete show get set list iam --help";;
        cascade)    cmds="account tenant info iam folder project cluster documentation help --non-interactive --log-file --output --detail --help --version";;
        maintain)    cmds="--folder --project";;
        login)    cmds="--tenant --refresh-token";;
        delete)    cmds="--folder --folder --project --folder --project";;
        *)    cmds="rename set show cluster export show-health merge-kubectl-auth iam upgrade group create namespace member add role resize import folder templates user tenant info account get-kubectl-auth versions region list remove project cascade maintain login delete";;
    esac

    COMPREPLY=( $(compgen -W "$cmds" -- "$cur") )

    return 0
}

complete -F _cascade_complete cascade

