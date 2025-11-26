#!/usr/bin/env bash

# if not interactive return early
[[ $- == *i* ]] || return

#set -xv

# Kiro CLI pre block. Keep at the top of this file.
[[ -f "${HOME}/Library/Application Support/kiro-cli/shell/bashrc.pre.bash" ]] && builtin source "${HOME}/Library/Application Support/kiro-cli/shell/bashrc.pre.bash"

export NIX_BUILD_CORES=12

export KUBECONFIG="${HOME}/.kube/config"

# Source global definitions
if [ -f /etc/bashrc ]; then
  source /etc/bashrc
fi

ulimit -n 4096

if [[ "$-" == *i* ]] && [[ ! -o login ]]; then
  if [[ -e ~/.bash_profile ]]; then
    . ~/.bash_profile
  fi
fi

if [ -n "${GHOSTTY_RESOURCES_DIR}" ]; then
  builtin source "${GHOSTTY_RESOURCES_DIR}/shell-integration/bash/ghostty.bash"
fi

declare -Ag _xspecs

if [[ "${ITERM_PROFILE}" == "Class" ]] || [[ "${ITERM_PROFILE}" == "Videos" ]] ; then
  export CLEAN_SHELL="true"
fi

export TZ='America/Los_Angeles'

# Don't forget to backup .inputrc (readline history searching)

#node (pre)
export PATH="/usr/local/opt/node@10/bin:${PATH}"

if [ -e "/usr/bin/uname" ]; then
  export UNAME=$(/usr/bin/uname)
  export ARCH=$(/usr/bin/uname -m)
else
  export UNAME=$(/usr/bin/env uname)
  export ARCH=$(/usr/bin/env uname -m)
fi

export UNAME2=$(echo "${UNAME}" | tr '[:upper:]' '[:lower:]')
export ARCH2="${ARCH}"

if [ "${ARCH2}" == "x86_64" ]; then
  export ARCH2="amd64"
fi

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# Set vi cli editing
set -o vi

# Functions
if [[ "${CLEAN_SHELL}" != "true" ]]; then
 export PROMPT_ID="🔴"
else
 export PROMPT_ID="🟢"
fi

if [ "${UNAME}" == "Darwin" ]; then
  if [ "${ARCH2}" == "arm64" ]; then
    export VAGRANT_DEFAULT_PROVIDER='parallels'
  else
    export VAGRANT_DEFAULT_PROVIDER='vmware_fusion'
  fi
fi

# Colorize stderr
color()(set -o pipefail;"$@" 2> >(sed $'s,.*,\e[31m&\e[m,'>&2))

function title {
    echo -ne "\033]0;${*}\007"
}

__call_navi() {
    printf "$(navi --print)"
}

bind '"\C-g": " \C-b\C-k \C-u`__call_navi`\e\C-e\C-a\C-y\C-h\C-e\e \C-y\ey\C-x\C-x\C-f"'

docs(){
  open "dash://${1}:${2}"
}

cdt() {
  pushd "$(git rev-parse --show-toplevel)" || return
}

codet() {
  code "$(git rev-parse --show-toplevel)"
}

# Configure some macOS specific settings
if [ "${UNAME}" == "Darwin" ]; then
  # See: https://www.mackungfu.org/UsabilityhackClickdraganywhereinmacOSwindowstomovethem
  defaults write -g NSWindowShouldDragOnGesture -bool true
  export SDKROOT=$(xcrun -sdk macosx --show-sdk-path)
fi

# Setup some macOS specific functions
if [ "${UNAME}" == "Darwin" ]; then
  dockerstop(){
    test -z "$(docker ps -q 2>/dev/null)" && osascript -e 'quit app "Docker"'
  }

  dockerstart(){
    open --background -a Docker
  }
fi

t() {
  fasdlist=$( fasd -d -l -r $1 | \
    fzf --query="$1 " --select-1 --exit-0 --height=25% --reverse --tac --no-sort --cycle) &&
    cd "$fasdlist" || true
}

function solver() {
  # See: https://github.com/javajon/katacoda-solver/releases
  SOLVER_IMAGE=ghcr.io/javajon/solver:0.5.4
  # Base source directory for challenges and scenarios
  SCENARIOS_ROOT=~/dev/spkane/oreilly/katacoda-sean-kane
  if [[ ! "$(pwd)" =~ ^$SCENARIOS_ROOT.* ]]; then
    echo "Please run this from $SCENARIOS_ROOT or one of its scenario or challenge subdirectory."
    return 1;
  fi
  SUBDIR=$(echo $(pwd) | ggrep -oP "^$SCENARIOS_ROOT\K.*")
  docker run --rm -it -v "$SCENARIOS_ROOT":/workdir -w /workdir/$SUBDIR $SOLVER_IMAGE "$@";
}


# Timeout shell session after 4 days - survive a weekend
export TMOUT=345600

export LC_CTYPE=en_US.UTF-8
export LC_ALL=en_US.UTF-8

export CLICOLOR=1
export LSCOLORS=gxBxhxDxfxhxhxhxhxcxcx
export GREP_COLOR='mt=1;30;43'

# Don't override the default TMPDIR on MacOS
if [ "${UNAME}" != "Darwin" ]; then
  export TMPDIR="/tmp"
fi

#Libraries
if [ "${UNAME}" == "Darwin" ]; then
    if [ "${ARCH2}" == "arm64" ]; then
      export LDFLAGS="-L/opt/homebrew/opt/zlib/lib -L/opt/homebrew/opt/sqlite/lib"
      export CPPFLAGS="-I/opt/homebrew/opt/zlib/include -I/opt/homebrew/opt/sqlite/include"
    else
      export LDFLAGS="-L/usr/local/opt/zlib/lib -L/usr/local/opt/sqlite/lib"
      export CPPFLAGS="-I/usr/local/opt/zlib/include -I/usr/local/opt/sqlite/include"
    fi
fi

#Calibre
export CALIBRE_CONFIG_DIRECTORY=/Volumes/Media/Books/calibre-prefs

#Slack
export SLACK_DEVELOPER_MENU=true

#LIMA/COLIMA
export LIMA_INSTANCE=colima

#1Password
export OP_BIOMETRIC_UNLOCK_ENABLED=true

#OPSCODE Chef
export OPSCODE_USER=spkane
export ORGNAME=imaging

#AWS
export AWS_CREDENTIAL_FILE="${HOME}/.aws/credentials"
export AWS_PROFILE="default"
export AWS_REGION="us-west-2"

# Claude
export MCP_LOG_LEVEL="ERROR"

#Vagrant
export LOCAL_SSH_PRIVATE_KEY=~/.ssh/vagrant-id
#export AWS_SSH_PRIVATE_KEY=~/.ssh/

#python
# pip should only run if there is a virtualenv currently activated
export PIP_REQUIRE_VIRTUALENV=false
export PYENV_VIRTUALENVWRAPPER_PREFER_PYVENV="true"

#docker
export BUILDKIT_COLORS="run=green:warning=yellow:error=red:cancel=cyan"

# misc
if [ "${UNAME}" == "Darwin" ]; then
  if [ "${ARCH2}" == "arm64" ]; then
    export XML_CATALOG_FILES=/opt/homebrew/etc/xml/catalog
  else
    export XML_CATALOG_FILES=/usr/local/etc/xml/catalog
  fi
fi
export PKG_CONFIG_PATH=${PKG_CONFIG_PATH}:/usr/local/lib/pkgconfig:/opt/X11/lib/pkgconfig

if [ -e "/usr/bin/bat" ] || [ -e "/usr/local/bin/bat"  ] || [ -e "/opt/homebrew/bin/bat"  ]; then
  export PAGER="bat"
elif [ -e "/usr/bin/less" ] || [ -e "/usr/local/bin/less"  ] || [ -e "/opt/homebrew/bin/less"  ]; then
  export PAGER="less"
else
  export PAGER="more"
fi

export PATH="/usr/local/bin:/usr/local/sbin:${PATH}:/sbin:/usr/sbin"

if [ "${UNAME}" == "SunOS" ]
then
  export PATH="$PATH:/usr/ucb"
fi

export PATH="${HOME}/.asdf/shims:${HOME}/bin:${KREW_ROOT:-$HOME/.krew}/bin:/opt/homebrew/bin:/opt/homebrew/sbin:${HOME}/.local/bin:${PATH}"

#Make git github aware
if [ -e "/usr/local/bin/hub" ] || [ -e "/opt/homebrew/bin/hub"  ] || [ -e "${HOME}/bin/hub"  ]; then
  eval "$(hub alias -s)"
fi

#thefuck
if [ -e "/usr/local/bin/thefuck" ] || [ -e "/opt/homebrew/bin/thefuck"  ]; then
  eval $(thefuck --alias u)
fi

# Lock and Load a custom theme file
# location /.bash_it/themes/
export PROMPT_DIRTRIM=2

function swagger(){
  docker run --rm -it --user $(id -u):$(id -g) -p 8085:8080 -e GOPATH=$(go env GOPATH):/go -e XDG_CACHE_HOME=/tmp/.cache -v $HOME:$HOME -w $(pwd) quay.io/goswagger/swagger "$@"
}

export EDITOR="vim"
# override git config
#export GIT_EDITOR="vim"

# Don't check mail when opening terminal.
unset MAILCHECK

# Set this to false to turn off version control status checking within the prompt for all themes
export SCM_CHECK=true

if [ "${UNAME}" == "Darwin" ]; then
  if [ "${ARCH2}" == "arm64" ]; then
    curlbin=$([ -d /opt/homebrew/Cellar/curl ] && find /opt/homebrew/Cellar/curl -name curl | grep bin | head -n 1)
    if [[ "${curlbin}" != "" ]]; then
      alias curl="${curlbin}"
    fi
  else
    curlbin=$([ -d /usr/local/Cellar/curl ] && find /usr/local/Cellar/curl -name curl | grep bin | head -n 1)
    if [[ "${curlbin}" != "" ]]; then
      alias curl="${curlbin}"
    fi
  fi
fi

# Grafana Loki
export LOKI_ADDR=http://localhost:3100

# Kubernetes Yaml - Quickly
export dr="--dry-run=client -o yaml"
export KUBECTL_KUBERC=true

alias acd-init-pw='kubecolor -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d'
alias ag="ag -f --hidden"
alias aga="ag -f --hidden -a"
alias agai="ag -f --hidden -a -i"
alias aptsearch="apt-cache search"
alias aptprovides="apt-file update; apt-file search"
alias aw="acidwarp -n -k"
alias awsume=". awsume"
alias chrome="chromium --ozone-platform=wayland"
if [ "${UNAME}" == "Darwin" ]; then
  if [ "${ARCH2}" == "arm64" ]; then
    alias clean-shell="env -i CLEAN_SHELL=\"true\" SHELL=\"/opt/homebrew/bin/bash\" TERM=\"xterm-256color\" HOME=\"$HOME\" LC_CTYPE=\"${LC_ALL:-${LC_CTYPE:-$LANG}}\" PATH=\"$PATH\" USER=\"$USER\" /opt/homebrew/bin/bash"
  else
    alias clean-shell="env -i CLEAN_SHELL=\"true\" SHELL=\"/usr/local/bin/bash\" TERM=\"xterm-256color\" HOME=\"$HOME\" LC_CTYPE=\"${LC_ALL:-${LC_CTYPE:-$LANG}}\" PATH=\"$PATH\" USER=\"$USER\" /usr/local/bin/bash"
  fi
else
  alias clean-shell="env -i CLEAN_SHELL=\"true\" SHELL=\"/usr/local/bin/bash\" TERM=\"xterm-256color\" HOME=\"$HOME\" LC_CTYPE=\"${LC_ALL:-${LC_CTYPE:-$LANG}}\" PATH=\"$PATH\" USER=\"$USER\" /usr/local/bin/bash"
fi
alias cidr="sipcalc"
alias clean-shell="env -i CLEAN_SHELL=\"true\" SHELL=\"/usr/local/bin/bash\" TERM=\"xterm-256color\" HOME=\"$HOME\" LC_CTYPE=\"${LC_ALL:-${LC_CTYPE:-$LANG}}\" PATH=\"$PATH\" USER=\"$USER\" /usr/local/bin/bash"
alias clr="clear && reset"
clrp() {
  unset $(compgen -v | grep -i "PROXY$")
}
alias ckbuild="nerdctl build --namespace k8s.io "
alias cstop="colima stop; kubecolor config unset current-context"
alias cstart="colima start --vz-rosetta --kubernetes-version v1.31.12+k3s1 --cpu 8 --memory 8 --disk 100 --runtime containerd --with-kubernetes --network-address && kubecolor config set current-context --namespace=default colima"
alias dc="docker compose"
alias docker-compose="docker compose"
alias dm="docker-machine"
alias drup="docker pull superorbital/drone-api && docker run -d --rm --name drone-api -p 8080:8080 superorbital/drone-api && docker logs drone-api | grep -i token"
alias drdown="docker rm -f drone-api"
alias ekstoken='aws eks get-token --cluster-name $(kubecolor config current-context | cut -d / -f 2) | jq .status.token'
alias esnap="ETCDCTL_API=3 etcdctl --endpoints https://127.0.0.1:2379 --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key snapshot save ./snapshot.db"
alias erestore="ETCDCTL_API=3 etcdctl --endpoints https://127.0.0.1:2379 --data-dir /var/lib/etcd-backup snapshot restore ./snapshot.db"
alias dns-flush-cache='sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder'
alias g="git"
alias ga="git add"
alias ga.="git add ."
alias gat="git add :/"
alias gtc="git add :/ && git commit"
alias gac="git add . && git commit"
alias gc="git commit"
alias gdoc="godoc -http=127.0.0.1:6060"
alias gpoh="git push origin HEAD"
alias gpohf="git push --force-with-lease origin HEAD"
alias gs="git status"
alias gd="git diff"
alias gds="git diff --staged"
alias glog="sudo log stream --level debug --predicate 'subsystem==\"com.mitchellh.ghostty\"'"
alias gterm="infocmp -x | ssh ${SSH_SERVER} -- tic -x -"
alias h="history | grep -i"
alias htop="sudo htop"
alias ibrew='echo Run: /bin/bash -c "\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
alias k="kubecolor"
alias ka="kubecolor api-resources"
alias kaf="kubecolor apply -f"
alias kc="kubecolor create"
alias kcf="kubecolor create -f"
alias kconf="kubeconform -summary -strict"
alias kcpualloc='kutil | grep % | awk '\''{print $1}'\'' | awk '\''{ sum += $1 } END { if (NR > 0) { print sum/(NR*20), "%\n" } }'\'''
alias kcpyd='kubecolor create pod -o yaml --dry-run=client'
alias kctx="kubectx"
alias kd='kubecolor describe'
alias kdel='kubecolor delete'
alias ke='kubecolor exec'
alias kevents="kubecolor get events -A --sort-by='{.lastTimestamp}'"
alias kex="kubecolor explain --recursive"
alias kg='kubecolor get'
alias kgp='kubecolor get pod'
alias kgsvcoyaml='kubecolor get service -o=yaml'
alias kgsvcslwn='watch kubecolor get service --show-labels --namespace'
alias kgsvcwn='watch kubecolor get service --namespace'
alias ki='kubecolor cluster-info'
alias kl='kubecolor logs'
alias kmemalloc='kutil | grep % | awk '\''{print $5}'\'' | awk '\''{ sum += $1 } END { if (NR > 0) { print sum/(NR*75), "%\n" } }'\'''
#alias kns="kubens"
function kns() {
  kubecolor config set-context --current --namespace=${1}
}
alias komgd='kubecolor delete --grace-period 0 --force'
alias kr='kubecolor run'
alias ksysgpo='kubecolor --namespace=kube-system get pod'
alias kun='kubecolor config unset current-context'
alias kus='kustomize'
alias kuse='kubecolor config use-context '
alias kutil='kubecolor get nodes --no-headers | awk '\''{print $1}'\'' | xargs -I {} sh -c '\''echo {} ; kubecolor describe node {} | grep Allocated -A 5 | grep -ve Event -ve Allocated -ve percent -ve -- ; echo '\'''
alias kw='watch -n 0.5 "kubecolor config current-context; echo ""; kubecolor config view | grep namespace; echo ""; kubecolor get namespace,node,ingress,pod,svc,job,cronjob,deployment,rs,pv,pvc,secret,ep -o wide"'
alias ldo="lazydocker"
alias lg="lazygit"
alias mdcat="pandoc -f markdown -t plain"
alias mtr="sudo mtr"
if command -v "op" &> /dev/null; then
  alias opl="eval \$(op signin my)"
fi
alias pe="pipenv"
alias pes="pipenv shell"
alias pc="/opt/homebrew/bin/pre-commit"
alias r="rg"
alias rmc="rm -rf ${HOME}/class/* && rm -f ${HOME}/class/.???*"
alias s="set -h && hash -r && _SHOW_MESSAGES=1 exec -a -bash bash"
alias sshkg="ssh-keygen -R"
alias stc-l='stc -homedir="/Users/spkane/Library/Application Support/Syncthing/"'
alias tf='terraform'
alias tfp="tf plan -no-color | grep -E '^[[:punct:]]|Plan'"
alias ungron="gron --ungron"
alias va="vagrant"
alias vlc='/Applications/VLC.app/Contents/MacOS/VLC'

if command -v "keychain" &> /dev/null; then
function load_keys {
  hash keychain 2>&- && eval "$(keychain --eval --agents ssh,gpg --inherit any id_ed25519_2020 B707FAABB70E763D)"
}
fi

#fasd
#alias a='fasd -a'        # any
#alias d='fasd -d'        # directory
#alias f='fasd -f'        # file
#alias s='fasd -si'       # show / search / select
#alias sd='fasd -sid'     # interactive directory selection
#alias sf='fasd -sif'     # interactive file selection
#alias z='fasd_cd -d'     # cd, same functionality as j in autojump
#alias zz='fasd_cd -d -i' # cd with interactive selection

# z.lua
#alias zz='z -c'      # restrict matches to subdirs of $PWD
#alias zi='z -i'      # cd with interactive selection
#alias zf='z -I'      # use fzf to select in multiple matches
#alias zb='z -b'      # quickly cd to the parent directory

# unalias
unalias sl 2> /dev/null

#GPG
GPG_TTY=$(tty)
export GPG_TTY
alias gpg-agent-reset="gpgconf --kill gpg-agent"

#Terraform
mkdir -p "${HOME}/.terraform-plugin-cache"
export TF_PLUGIN_CACHE_DIR="${HOME}/.terraform-plugin-cache"

#pipenv
export PIPENV_MAX_DEPTH=4

if [[ -e /usr/bin/manpath ]]; then
  MANPATH="$(/usr/bin/manpath -q):${HOME}/man"
  export MANPATH
else
  MANPATH="$(/usr/bin/env manpath -q):${HOME}/man"
  export MANPATH
fi

export ANSIBLE_NOCOWS=1
export ANSIBLE_VAULT_PASSWORD_FILE="./.vault_pass"

# RVC
if [ "${UNAME}" != "Darwin" ]; then
  export RVC_READLINE=/usr/local/Cellar/readline/8.0.4/lib/libreadline.dylib
fi

#pyenv
if [ "${UNAME}" != "Darwin" ]; then
    if [ "${ARCH2}" == "arm64" ]; then
      alias pyenv="CFLAGS=\"-I$([ -f /opt/homebrew/bin/brew ] && brew --prefix openssl)/include\" LDFLAGS=\"-L$([ -f /opt/homebrew/bin/brew ] && brew --prefix openssl)/lib\" pyenv "
    else
      alias pyenv="CFLAGS=\"-I$([ -f /usr/local/bin/brew ] && brew --prefix openssl)/include\" LDFLAGS=\"-L$([ -f /usr/local/bin/brew ] && brew --prefix openssl)/lib\" pyenv "
    fi
fi

#rbenv (Do we need this for asdf?)
#if [ "${UNAME}" != "Darwin" ]; then
#  if [ "${ARCH2}" == "arm64" ]; then
#    alias rbenv="RUBY_CONFIGURE_OPTS=\"--with-openssl-dir=$([ -f /opt/homebrew/bin/brew ] && brew --prefix openssl)\" rbenv "
#  else
#    alias rbenv="RUBY_CONFIGURE_OPTS=\"--with-openssl-dir=$([ -f /usr/local/bin/brew ] && brew --prefix openssl)\" rbenv "
#  fi
#fi

#tfenv
export TFENV_AUTO_INSTALL=true

#pianobar
if [ "${UNAME}" != "Darwin" ]; then
  alias pianobar='osascript -e '"'"'tell application "Terminal" to do script "pianokeys"'"'"' && pianobar'
fi

#Bash History
export HISTSIZE=10000
export HISTFILESIZE=100000
export HISTCONTROL=ignoreboth:erasedups
export HISTTIMEFORMAT="%d/%m/%y %T "
export HISTIGNORE="ls:pwd:clear:reset:[bf]g:exit"
shopt -s histappend

#xonsh
export FOREIGN_ALIASES_OVERRIDE=True

if [[ -z "$LC_EXTRATERM_COOKIE" ]]; then
  PROMPT_COMMAND="history -a; history -r; history -n; ${PROMPT_COMMAND}"
fi

#Apply our completions last
[[ -r "/usr/local/etc/profile.d/bash_completion.sh" ]] && source "/usr/local/etc/profile.d/bash_completion.sh"
[[ -r "/opt/homebrew/etc/profile.d/bash_completion.sh" ]] && . "/opt/homebrew/etc/profile.d/bash_completion.sh"


export BASH_COMPLETION_USER_DIR="${HOME}/.bash_completion.d:/opt/homebrew/etc/bash_completion.d:/usr/local/etc/bash_completion.d:/etc/bash_completion.d"

(readonly | cut -d= -f1 | cut -d' ' -f3 | grep -q BASH_COMPLETION_COMPAT_DIR) || export BASH_COMPLETION_COMPAT_DIR="/usr/local/etc/bash_completion.d"

# Defer mise activation until after all PATH modifications

if command -v "kubectl-argo-rollouts" &> /dev/null; then
  eval "kubectl-argo-rollouts completion bash"
fi

if command -v "fzf" &> /dev/null; then
  eval "$(fzf --bash)"
fi

if command -v "pack" &> /dev/null; then
  eval "$(pack --show-completion)"
fi

[ -f ~/.fzf.bash ] && eval ~/.fzf.bash
export FZF_DEFAULT_OPS="--extended"

# This appears to break incoming SCP in at least some circumstances...
if [[ $- == *i* ]]; then
  if command -v "pipenv" &> /dev/null; then
    eval "$(_PIPENV_COMPLETE=bash_source pipenv)"
  fi
fi

if command -v "logcli" &> /dev/null; then
  eval "$(logcli --completion-script-bash)"
fi

if command -v "cludo" &> /dev/null; then
    eval "$(cludo completion bash)"
fi

if command -v "golangci-lint" &> /dev/null; then
  eval "$(golangci-lint completion bash)"
fi

if command -v "kubectl" &> /dev/null; then
  eval "$(kubectl completion bash)"
fi

if command -v "register-python-argcomplete" &> /dev/null; then
  eval "$(register-python-argcomplete pipx)"
fi

if command -v "velero" &> /dev/null; then
  eval "$(velero completion bash)"
fi

if command -v "limactl" &> /dev/null; then
  eval "$(limactl completion bash)"
fi

if command -v "op" &> /dev/null; then
  eval "$(op completion bash)"
fi

complete -C aws_completer aws
complete -F __start_kubectl k kubecolor

#Rust
export PATH="$HOME/.cargo/bin:$PATH"

# Golang
export PATH="/usr/local/go/bin:$PATH"
export GOPATH="/Users/${USER}/dev/go/path"
if [[ -f /usr/local/bin/go ]]; then
  GOROOT=$(/usr/local/bin/go env GOROOT)
elif [[ -f /opt/homebrew/bin/go ]]; then
  GOROOT=$(/opt/homebrew/bin/go env GOROOT)
else
  GOROOT=$(go env GOROOT)
fi
export GOROOT
mkdir -p ${HOME}/dev/go/
if [ "${UNAME}" == "Darwin" ]; then
  ln -sfh "${GOROOT}" "/${HOME}/dev/go/root" 2> /dev/null
else
  ln -sfL "${GOROOT}" "${HOME}/dev/go/root" 2> /dev/null
fi

if $(cd /usr/local/go 2> /dev/null); then
  PASS=TRUE # noop
else
  echo "Prmopting for sudo password to create GOROOT link."
  sudo mkdir -p /usr/local
  sudo rm -f /usr/local/go
  if [ "${UNAME}" == "Darwin" ]; then
    sudo ln -sfL "${GOROOT}" /usr/local/go
  else
    sudo ln -sfL "${GOROOT}" /usr/local/go
  fi
fi
export MYGOBIN="$GOPATH/bin"
export PATH="${MYGOBIN}:${PATH}"
export GOPRIVATE="git.ask.com"
export GOARCH="${ARCH2}"
export GOOS="${UNAME2}"
#export CGO_ENABLED=1

#Wayland
export XDG_SESSION_TYPE=wayland
export ELECTRON_OZONE_PLATFORM_HINT=auto

if command -v "dyff" &> /dev/null; then
  export KUBECTL_EXTERNAL_DIFF="dyff between --omit-header --set-exit-code"
fi

#if [[ -e /opt/homebrew/opt/z.lua/share/z.lua/z.lua ]]; then
#  eval "$(lua /opt/homebrew/opt/z.lua/share/z.lua/z.lua --init bash enhanced once echo fzf)"
#fi

if command -v "zoxide" &> /dev/null; then
  eval "$(zoxide init bash)"
  export _ZO_DOCTOR=0
fi

if command -v "fasd" &> /dev/null; then
  eval "$(fasd --init auto)"
fi

if command -v "direnv" &> /dev/null; then
  eval "$(direnv hook bash)"
fi

touch "${HOME}/.bashrc.personal"
for i in $(\ls -C1 ${HOME}/.bashrc.personal*); do
    source "${i}"
done

export PATH="$PATH:/Users/${USER}/.local/bin:/Applications/Godot_mono.app/Contents/MacOS/"

# gcloud
if [[ -f /usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.bash.inc ]]; then
  source "/usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.bash.inc"
elif [[ -f /opt/homebrew/share/google-cloud-sdk/path.bash.inc ]]; then
  source "/opt/homebrew/share/google-cloud-sdk/path.bash.inc"
fi

# Activate mise AFTER all other PATH modifications to ensure mise tools are first
if command -v "mise" &> /dev/null; then
  eval "$(mise activate bash)"
fi

# Virtualenv activation commented out to allow mise Python to take precedence
# Uncomment if you need the global virtualenv, or activate manually when needed
# source ~/.venv/bin/activate

# JINA_CLI_BEGIN

## autocomplete
_jina() {
  COMPREPLY=()
  local word="${COMP_WORDS[COMP_CWORD]}"

  if [ "$COMP_CWORD" -eq 1 ]; then
    COMPREPLY=( $(compgen -W "$(jina commands)" -- "$word") )
  else
    local words=("${COMP_WORDS[@]}")
    unset words[0]
    unset words[$COMP_CWORD]
    local completions=$(jina completions "${words[@]}")
    COMPREPLY=( $(compgen -W "$completions" -- "$word") )
  fi
}

complete -F _jina jina

# session-wise fix
ulimit -n 4096
export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES
# default workspace for Executors
export JINA_DEFAULT_WORKSPACE_BASE="${HOME}/.jina/executor-workspace"

# JINA_CLI_END

### MANAGED BY RANCHER DESKTOP START (DO NOT EDIT)
export PATH="$PATH:/Users/spkane/.rd/bin"
### MANAGED BY RANCHER DESKTOP END (DO NOT EDIT)

for file in ${HOME}/.bash_completions/*; do
  if [[ -e "$file" && -r "$file" ]]; then
    source "$file"
  fi
done

# Added by LM Studio CLI (lms)
export PATH="$PATH:/Users/seankane/.lmstudio/bin"
# End of LM Studio CLI section


# Unset __zsh_like_cd if it exists to prevent errors
unset -f cd 2>/dev/null

# Kiro CLI post block. Keep at the bottom of this file.
[[ -f "${HOME}/Library/Application Support/kiro-cli/shell/bashrc.post.bash" ]] && builtin source "${HOME}/Library/Application Support/kiro-cli/shell/bashrc.post.bash"

mkdir -p "${HOME}/tmp"
touch "${HOME}/tmp/bashrc.run"
