#!/usr/bin/env bash

export BASH_SILENCE_DEPRECATION_WARNING=1

# If not running interactively, don't do anything
[[ $- == *i* ]] || return 0

# Kiro CLI pre block. Keep at the top of this file.
[[ -f "${HOME}/Library/Application Support/kiro-cli/shell/bash_profile.pre.bash" ]] && builtin source "${HOME}/Library/Application Support/kiro-cli/shell/bash_profile.pre.bash"

if [ -f ~/.bashrc ]; then
  source ~/.bashrc
fi

if [ -e "/usr/bin/uname" ]; then
  export UNAME=$(/usr/bin/uname)
  export ARCH=$(/usr/bin/uname -m)
else
  export UNAME=$(/usr/bin/env uname)
  export ARCH=$(/usr/bin/env uname -m)
fi

#if [ "${UNAME}" == "Darwin" ]; then
#  export SSH_AUTH_SOCK=${HOME}/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh
#elif
if command -v "keychain" &> /dev/null; then
  hash keychain 2>&- && eval "$(keychain --eval --agents ssh,gpg --inherit any id_ed25519_2020 B707FAABB70E763D)"
fi

gpip(){
  PIP_REQUIRE_VIRTUALENV="" pip "$@"
}

if command -v "dadjoke" &> /dev/null; then
  echo
  dadjoke random 2> /dev/null
  echo
fi

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/usr/local/google-cloud-sdk/path.bash.inc' ]; then source '/usr/local/google-cloud-sdk/path.bash.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/usr/local/google-cloud-sdk/completion.bash.inc' ]; then source '/usr/local/google-cloud-sdk/completion.bash.inc'; fi

test -e "${HOME}/.cargo/env" && source "${HOME}/.cargo/env"

export PATH="$PATH:/Users/spkane/.local/bin"

# This is tricky to make generic due to the use of both tfenv and homebrew...
#complete -C /usr/local/Cellar/tfenv/3.0.0/versions/1.2.9/terraform terraform
complete -C /Users/spkane/dev/superorbital/infrastructure/bin/Darwin/x86_64/terraform terraform

export DISPLAY=":0"

### MANAGED BY RANCHER DESKTOP START (DO NOT EDIT)
export PATH="$PATH:/Users/spkane/.rd/bin"
### MANAGED BY RANCHER DESKTOP END (DO NOT EDIT)PATH="/opt/podman/bin:$PATH"
export PATH="$PATH:/opt/podman/bin"

if type brew &>/dev/null
then
  HOMEBREW_PREFIX="$(brew --prefix)"
  if [[ -r "${HOMEBREW_PREFIX}/etc/profile.d/bash_completion.sh" ]]
  then
    source "${HOMEBREW_PREFIX}/etc/profile.d/bash_completion.sh"
  else
    for COMPLETION in "${HOMEBREW_PREFIX}/etc/bash_completion.d/"*
    do
      [[ -r "${COMPLETION}" ]] && source "${COMPLETION}"
    done
  fi
fi

if command -v "iterm2_prompt_mark" &> /dev/null; then
  function blastoff(){
    if ! { [ "$TERM" = "screen" ] && [ -n "$TMUX" ]; } then
      echo -n "$(iterm2_prompt_mark)"
   fi
  }
  export starship_precmd_user_func="blastoff"
fi

_convert_pc_to_array() {
  mapfile -t _PROMPT_COMMAND <<<"${PROMPT_COMMAND}"
  unset PROMPT_COMMAND
  PROMPT_COMMAND=("${_PROMPT_COMMAND[@]}")
}

declare -ga preexec_functions=()
declare -ga precmd_functions=()

if [ -x $HOMEBREW_PREFIX/bin/starship ]; then
  eval "$(starship init bash)"
  _convert_pc_to_array
elif command -v "starship" &> /dev/null; then
  eval "$(/usr/bin/env starship init bash)"
fi

test -e "/opt/homebrew/opt/asdf/libexec/asdf.sh" && source /opt/homebrew/opt/asdf/libexec/asdf.sh

test -e "${HOME}/.iterm2_shell_integration.bash" && source "${HOME}/.iterm2_shell_integration.bash"

export PATH="/opt/homebrew/opt/m4/bin:$PATH"

# Added by OrbStack: command-line tools and integration
source ~/.orbstack/shell/init.bash 2>/dev/null || :

export PATH=/Users/spkane/local/bin:$PATH

[[ -r "/opt/homebrew/etc/profile.d/bash_completion.sh" ]] && . "/opt/homebrew/etc/profile.d/bash_completion.sh"

# Added by LM Studio CLI (lms)
export PATH="$PATH:/Users/seankane/.lmstudio/bin"
# End of LM Studio CLI section

# Bash Completions
[[ -r "/opt/homebrew/etc/profile.d/bash_completion.sh" ]] && . "/opt/homebrew/etc/profile.d/bash_completion.sh"
[[ -r "/etc/profile.d/bash_completion.sh" ]] && . "/etc/profile.d/bash_completion.sh"

# Kiro CLI post block. Keep at the bottom of this file.
[[ -f "${HOME}/Library/Application Support/kiro-cli/shell/bash_profile.post.bash" ]] && builtin source "${HOME}/Library/Application Support/kiro-cli/shell/bash_profile.post.bash"
