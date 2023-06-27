#!/usr/bin/env bash

export BASH_SILENCE_DEPRECATION_WARNING=1

# If not running interactively, don't do anything
[[ $- == *i* ]] || return

if [ -f ~/.bashrc ]; then
   source ~/.bashrc
fi

if [ -e "/usr/bin/uname" ]; then
  export UNAME=$(/usr/bin/uname)
  export ARCH=$(/usr/bin/uname -m)
else
  export UNAME=$(/bin/uname)
  export ARCH=$(/bin/uname -m)
fi

#if [ "${UNAME}" == "Darwin" ]; then
#  export SSH_AUTH_SOCK=${HOME}/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh
#elif
if command -v "keychain" &> /dev/null; then
  hash keychain 2>&- && eval "$(keychain --eval --agents ssh,gpg --inherit any id_ed25519_2020 id_ed25519_sean_so 0845757D65596830)"
fi

gpip(){
  PIP_REQUIRE_VIRTUALENV="" pip "$@"
}

test -e "${HOME}/.iterm2_shell_integration.bash" && source "${HOME}/.iterm2_shell_integration.bash"

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


### MANAGED BY RANCHER DESKTOP START (DO NOT EDIT)
export PATH="$PATH:/Users/spkane/.rd/bin"
### MANAGED BY RANCHER DESKTOP END (DO NOT EDIT)PATH="/opt/podman/bin:$PATH"
export PATH="$PATH:/opt/podman/bin"
