#!/usr/bin/env bash
# Bash completion for keychain
# https://github.com/danielrobbins/keychain
#
# Original script by Mikko Koivunalho (@mikkoi)
# https://github.com/mikkoi/keychain-bash-completion
# Enhanced with --extended mode support by Daniel Robbins

__keychain_init_completion() {
    COMPREPLY=()
    _get_comp_words_by_ref cur prev words cword
}

# Get ssh key file names. Find all files with .pub suffix and remove the suffix
__keychain_ssh_keys() {
    if [ -d ~/.ssh ]; then
        keys=()
        while IFS= read -r -d '' file; do
            key="$(basename -s .pub "$file")"
            keys+=( "$key" )
        done < <(\find "${HOME}/.ssh" -type f -name \*.pub -print0)
        echo "${keys[*]}"
    fi
}

# Get gpg keys - 8-character short key IDs
__keychain_gpg_keys() {
    keys=()
    while IFS= read -r row; do
        if [[ "$row" =~ ^sec:[a-z]:[[:digit:]]{0,}:[[:alnum:]]{0,}:([[:alnum:]]{0,}): ]]; then
            key="$(echo "${BASH_REMATCH[1]}" | cut -b 9-16)"
            keys+=( "$key" )
        fi
    done < <(\gpg --list-secret-keys --with-colons 2>/dev/null)
    echo "${keys[*]}"
}

# Get hostnames from ~/.ssh/config
__keychain_ssh_config_hosts() {
    if [ -f ~/.ssh/config ]; then
        # Extract Host entries, excluding wildcards
        grep -i "^Host " ~/.ssh/config 2>/dev/null | \
            awk '{print $2}' | \
            grep -v '[*?]'
    fi
}

# Parse command-line options from keychain --help output
__keychain_command_line_options() {
    opts=()
    # Try to find keychain executable (handle Git Bash/MINGW64 PATH issues)
    local keychain_cmd
    if command -v keychain >/dev/null 2>&1; then
        keychain_cmd="keychain"
    elif [ -x ./keychain ]; then
        keychain_cmd="./keychain"
    elif [ -x ./keychain.sh ]; then
        keychain_cmd="./keychain.sh"
    else
        # Fallback: provide common options if keychain not found
        echo "-h --help -V --version -q --quiet -Q --quick"
        return 0
    fi

    while IFS= read -r row; do
        # Match: "    -X --option" format (short first, long second)
        if [[ "$row" =~ ^[[:space:]]{4}([-]{1}[[:alpha:]]{1})[[:space:]]{1,}([-]{2}[[:alnum:]-]{1,})[[:space:]]{0,} ]]
        then
            opt1="${BASH_REMATCH[1]}"
            opts+=( "$opt1" )
            opt2="${BASH_REMATCH[2]}"
            opts+=( "$opt2" )
        # Match: "    --option" format (long only)
        elif [[ "$row" =~ ^[[:space:]]{4}([-]{2}[[:alnum:]-]{1,})[[:space:]]{1,} ]]
        then
            opt="${BASH_REMATCH[1]}"
            opts+=( "$opt" )
        fi
    done < <("$keychain_cmd" --help 2>/dev/null)
    echo "${opts[*]}"
}

_keychain() {
    local cur

    if declare -F _init_completion >/dev/null 2>&1; then
        _init_completion -n : || return
    else
        # Fallback if bash-completion not available
        COMPREPLY=()
        cur="${COMP_WORDS[COMP_CWORD]}"
    fi

    # Check if --extended is in the command line
    local extended_mode=false
    for word in "${COMP_WORDS[@]}"; do
        [[ "$word" == "--extended" ]] && extended_mode=true && break
    done

    # Handle --extended mode completions with prefixes
    if [[ "$extended_mode" == true ]]; then
        local prefix completions=()

        # Determine which prefix type we're completing
        case "$cur" in
            sshk:*)
                # shellcheck disable=SC2207
                local items=( $(__keychain_ssh_keys) )
                prefix="sshk:"
                ;;
            gpgk:*)
                # shellcheck disable=SC2207
                local items=( $(__keychain_gpg_keys) )
                prefix="gpgk:"
                ;;
            host:*)
                # shellcheck disable=SC2207
                local items=( $(__keychain_ssh_config_hosts) )
                prefix="host:"
                ;;
            s*|g*|h*)
                # Handle partial prefix matches (s->sshk:, g->gpgk:, h->host:)
                # Only if no colon present yet
                [[ ! "$cur" =~ : ]] || return 0
                [[ "sshk:" == "$cur"* ]] && completions+=( "sshk:" )
                [[ "gpgk:" == "$cur"* ]] && completions+=( "gpgk:" )
                [[ "host:" == "$cur"* ]] && completions+=( "host:" )
                # If we have prefix matches, show them
                if [ ${#completions[@]} -gt 0 ]; then
                    # shellcheck disable=SC2207
                    COMPREPLY=( $(compgen -W "${completions[*]}" -- "$cur") )
                    compopt -o nospace 2>/dev/null
                fi
                # Also add matching options
                # shellcheck disable=SC2207
                local opts=( $(__keychain_command_line_options) )
                if [ ${#opts[@]} -gt 0 ]; then
                    # shellcheck disable=SC2207
                    COMPREPLY+=( $(compgen -W "${opts[*]}" -- "$cur") )
                fi
                return 0
                ;;
            -*)
                # Show options only
                # shellcheck disable=SC2207
                local opts=( $(__keychain_command_line_options) )
                if [ ${#opts[@]} -gt 0 ]; then
                    # shellcheck disable=SC2207
                    COMPREPLY=( $(compgen -W "${opts[*]}" -- "$cur") )
                fi
                return 0
                ;;
            *)
                # No prefix yet, offer all prefixed possibilities
                # shellcheck disable=SC2207
                local ssh_keys=( $(__keychain_ssh_keys) )
                # shellcheck disable=SC2207
                local gpg_keys=( $(__keychain_gpg_keys) )
                # shellcheck disable=SC2207
                local hosts=( $(__keychain_ssh_config_hosts) )

                for key in "${ssh_keys[@]}"; do completions+=( "sshk:$key" ); done
                for key in "${gpg_keys[@]}"; do completions+=( "gpgk:$key" ); done
                for host in "${hosts[@]}"; do completions+=( "host:$host" ); done

                # shellcheck disable=SC2207
                COMPREPLY=( $(compgen -W "${completions[*]}" -- "$cur") )
                __ltrim_colon_completions "$cur" 2>/dev/null || true
                compopt -o nospace 2>/dev/null
                return 0
                ;;
        esac

        # Build completions for sshk:/gpgk:/host: prefixes
        if [[ -n "$prefix" ]]; then
            for item in "${items[@]}"; do
                completions+=( "${prefix}${item}" )
            done
            # shellcheck disable=SC2207
            COMPREPLY=( $(compgen -W "${completions[*]}" -- "$cur") )
            __ltrim_colon_completions "$cur" 2>/dev/null || true
            compopt -o nospace 2>/dev/null
            return 0
        fi
    fi

    # Normal mode (no --extended): complete bare keys and options
    # shellcheck disable=SC2207
    COMPREPLY=( $(compgen -W "$(__keychain_command_line_options) $(__keychain_ssh_keys) $(__keychain_gpg_keys)" -- "$cur") )
    return 0
}

complete -F _keychain keychain
