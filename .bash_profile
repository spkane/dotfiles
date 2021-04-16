#!/usr/bin/env bash

export BASH_SILENCE_DEPRECATION_WARNING=1

if [ -f ~/.bashrc ]; then
   source ~/.bashrc
fi

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

if command -v "keychain" &> /dev/null; then
  hash keychain 2>&- && eval "$(keychain --eval --agents ssh,gpg --inherit any id_ed25519_2020 0845757D65596830)"
fi

gpip(){
  PIP_REQUIRE_VIRTUALENV="" pip "$@"
}

test -e "${HOME}/.iterm2_shell_integration.bash" && source "${HOME}/.iterm2_shell_integration.bash"

if command -v "dadjoke" &> /dev/null; then
  echo
  dadjoke
  echo
fi

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/usr/local/google-cloud-sdk/path.bash.inc' ]; then source '/usr/local/google-cloud-sdk/path.bash.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/usr/local/google-cloud-sdk/completion.bash.inc' ]; then source '/usr/local/google-cloud-sdk/completion.bash.inc'; fi

test -e "${HOME}/.cargo/env" && source "${HOME}/.cargo/env"
