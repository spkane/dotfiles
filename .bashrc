#!/usr/bin/env bash

#set -xv

# Source global definitions
if [ -f /etc/bashrc ]; then
  source /etc/bashrc
fi

if [[ "${ITERM_PROFILE}" == "Class" ]]; then
  export CLEAN_SHELL="true"
fi

export VAGRANT_DEFAULT_PROVIDER='vmware_fusion'

# Don't forget to backup .inputrc (readline history searching)

#node (pre)
export PATH="/usr/local/opt/node@10/bin:${PATH}"

if [ -e "/usr/bin/uname" ]; then
  UNAME=$(/usr/bin/uname)
else
  UNAME=$(/bin/uname)
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

if [ "${UNAME}" != "Darwin" ]; then
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

# Timeout shell session after 4 days - survive a weekend
export TMOUT=345600

export LC_CTYPE=en_US.UTF-8
export LC_ALL=en_US.UTF-8

export CLICOLOR=1
export LSCOLORS=gxBxhxDxfxhxhxhxhxcxcx
export GREP_COLOR='1;30;43'

# Don't override the default TMPDIR on MacOS
if [ "${UNAME}" != "Darwin" ]; then
    export TMPDIR="/tmp"
fi

#Libraries
export LDFLAGS="-L/usr/local/opt/zlib/lib -L/usr/local/opt/sqlite/lib"
export CPPFLAGS="-I/usr/local/opt/zlib/include -I/usr/local/opt/sqlite/include"

#OPSCODE Chef
export OPSCODE_USER=spkane
export ORGNAME=imaging

#AWS
export AWS_CREDENTIAL_FILE="${HOME}/.aws/credentials"

#Vagrant
export LOCAL_SSH_PRIVATE_KEY=~/.ssh/vagrant-id
export AWS_SSH_PRIVATE_KEY=~/.ssh/

#python
# pip should only run if there is a virtualenv currently activated
export PIP_REQUIRE_VIRTUALENV=false
export PYENV_VIRTUALENVWRAPPER_PREFER_PYVENV="true"

# misc
export XML_CATALOG_FILES=/usr/local/etc/xml/catalog
export PKG_CONFIG_PATH=${PKG_CONFIG_PATH}:/usr/local/lib/pkgconfig:/opt/X11/lib/pkgconfig

if [ -e "/usr/bin/less" ] || [ -e "/usr/local/bin/less"  ]; then
  export PAGER="less"
else
  export PAGER="more"
fi

PATH="$HOME/bin:/usr/local/bin:/usr/local/sbin:$PATH:/sbin:/usr/sbin"

if [ "${UNAME}" == "SunOS" ]
then
  PATH="$PATH:/usr/ucb"
fi

#Make git github aware
if [ -e "/usr/local/bin/hub" ] || [ -e "${HOME}/bin/hub"  ]; then
  eval "$(hub alias -s)"
fi

#rbenv
if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi

# Do this after rbenv
export PATH="/usr/local/bin:${PATH}"

# Lock and Load a custom theme file
# location /.bash_it/themes/
export PROMPT_DIRTRIM=2

test -e "${HOME}/.iterm2_shell_integration.bash" && source "${HOME}/.iterm2_shell_integration.bash"

function blastoff(){
  if ! { [ "$TERM" = "screen" ] && [ -n "$TMUX" ]; } then
    echo -n "$(iterm2_prompt_mark)"
  fi
}
export starship_precmd_user_func="blastoff"

if command -v "starship" &> /dev/null; then
  eval "$(starship init bash)"
fi

function swagger(){
  docker run --rm -it --user $(id -u):$(id -g) -p 8085:8080 -e GOPATH=$(go env GOPATH):/go -e XDG_CACHE_HOME=/tmp/.cache -v $HOME:$HOME -w $(pwd) quay.io/goswagger/swagger "$@"
}

export EDITOR="vim"
export GIT_EDITOR="vim"

# Don't check mail when opening terminal.
unset MAILCHECK

# Set this to false to turn off version control status checking within the prompt for all themes
export SCM_CHECK=true

if [ "${UNAME}" == "Darwin" ]; then
  curlbin=$([ -d /usr/local/Cellar/curl ] && find /usr/local/Cellar/curl -name curl | grep bin | head -n 1)
  alias curl="${curlbin}"
fi

# Kubernetes Yaml - Quickly
export dr="--dry-run=client -o yaml"

alias ag="ag -f --hidden"
alias aga="ag -f --hidden -a"
alias agai="ag -f --hidden -a -i"
alias aptsearch="apt-cache search"
alias aptprovides="apt-file update; apt-file search"
alias clean-shell="env -i CLEAN_SHELL=\"true\" SHELL=\"/usr/local/bin/bash\" TERM=\"xterm-256color\" HOME=\"$HOME\" LC_CTYPE=\"${LC_ALL:-${LC_CTYPE:-$LANG}}\" PATH=\"$PATH\" USER=\"$USER\" /usr/local/bin/bash"
alias dc="docker-compose"
alias dm="docker-machine"
alias ekstoken='aws eks get-token --cluster-name $(kubectl config current-context | cut -d / -f 2) | jq .status.token'
alias esnap="ETCDCTL_API=3 etcdctl --endpoints https://127.0.0.1:2379 --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key snapshot save ./snapshot.db"
alias erestore="ETCDCTL_API=3 etcdctl --endpoints https://127.0.0.1:2379 --data-dir /var/lib/etcd-backup snapshot restore ./snapshot.db"
alias g="git"
alias gdoc="godoc -http=127.0.0.1:6060"
alias gpoh="git push origin HEAD"
alias gpohf="git push -f origin HEAD"
alias h="history"
alias htop="sudo htop"
alias ibrew='echo Run: /bin/bash -c "\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
alias k="kubectl"
alias ka="kubectl api-resources"
alias kaf="kubectl apply -f"
alias kc="kubectl create"
alias kcf="kubectl create -f"
alias kconf="kubeconform -summary -strict"
alias kcpualloc='kutil | grep % | awk '\''{print $1}'\'' | awk '\''{ sum += $1 } END { if (NR > 0) { print sum/(NR*20), "%\n" } }'\'''
alias kcpyd='kubectl create pod -o yaml --dry-run=client'
alias kctx="kubectx"
alias kd='kubectl describe'
alias kdf="kubectl delete -f"
alias kevents="kubectl get events -A --sort-by='{.lastTimestamp}'"
alias kex="kubectl explain --recursive"
alias kg='kubectl get'
alias kgp='kubectl get pod'
alias kgsvcoyaml='kubectl get service -o=yaml'
alias kgsvcslwn='watch kubectl get service --show-labels --namespace'
alias kgsvcwn='watch kubectl get service --namespace'
alias ki='kubectl cluster-info'
alias kl='kubectl logs'
alias kmemalloc='kutil | grep % | awk '\''{print $5}'\'' | awk '\''{ sum += $1 } END { if (NR > 0) { print sum/(NR*75), "%\n" } }'\'''
#alias kns="kubens"
alias kns='kubectl config set-context --current --namespace='
alias komgd='kubectl delete --grace-period 0 --force'
alias kr='kuebctl run'
alias ksysgpo='kubectl --namespace=kube-system get pod'
alias kutil='kubectl get nodes --no-headers | awk '\''{print $1}'\'' | xargs -I {} sh -c '\''echo {} ; kubectl describe node {} | grep Allocated -A 5 | grep -ve Event -ve Allocated -ve percent -ve -- ; echo '\'''
alias kw='watch -n 0.5 "kubectl config current-context; echo ""; kubectl config view | grep namespace; echo ""; kubectl get namespace,node,ingress,pod,svc,job,cronjob,deployment,rs,pv,pvc,secret,ep -o wide"'
alias ld="lazydocker"
alias lg="lazygit"
alias mdcat="pandoc -f markdown -t plain"
alias mtr="sudo mtr"
if command -v "op" &> /dev/null; then
  alias opl="eval \$(op signin my)"
fi
alias pe="pipenv"
alias pes="pipenv shell"
alias r="rg"
alias sshkg="ssh-keygen -R"
alias tf='terraform'
alias tfp="tf plan -no-color | grep -E '^[[:punct:]]|Plan'"
alias ungron="gron --ungron"
alias va="vagrant"
alias vlc='/Applications/VLC.app/Contents/MacOS/VLC'

if command -v "keychain" &> /dev/null; then
  function load_keys {
    hash keychain 2>&- && eval "$(keychain --eval --agents ssh,gpg --inherit any id_ed25519_2020 0845757D65596830 FB4CAF2F3EE9E5C9 7A54FF362955E1BE)"
  }
fi

#fasd
alias a='fasd -a'        # any
alias d='fasd -d'        # directory
alias f='fasd -f'        # file
alias s='fasd -si'       # show / search / select
alias sd='fasd -sid'     # interactive directory selection
alias sf='fasd -sif'     # interactive file selection
alias z='fasd_cd -d'     # cd, same functionality as j in autojump
alias zz='fasd_cd -d -i' # cd with interactive selection

# unalias
unalias sl 2> /dev/null

#GPG
GPG_TTY=$(tty)
export GPG_TTY

#pipenv
export PIPENV_MAX_DEPTH=4

MANPATH="$(/usr/bin/manpath):${HOME}/man"
export MANPATH

export ANSIBLE_NOCOWS=1

# RVC
if [ "${UNAME}" != "Darwin" ]; then
  export RVC_READLINE=/usr/local/Cellar/readline/8.0.4/lib/libreadline.dylib
fi

#pyenv
if [ "${UNAME}" != "Darwin" ]; then
  alias pyenv="CFLAGS=\"-I$([ -f /usr/local/bin/brew ] && brew --prefix openssl)/include\" LDFLAGS=\"-L$([ -f /usr/local/bin/brew ] && brew --prefix openssl)/lib\" pyenv "
fi

#rbenv
if [ "${UNAME}" != "Darwin" ]; then
  alias rbenv="RUBY_CONFIGURE_OPTS=\"--with-openssl-dir=$([ -f /usr/local/bin/brew ] && brew --prefix openssl)\" rbenv "
fi

#pianobar
if [ "${UNAME}" != "Darwin" ]; then
  alias pianobar='osascript -e '"'"'tell application "Terminal" to do script "pianokeys"'"'"' && pianobar'
fi

#Bash History
export HISTSIZE=5000
export HISTFILESIZE=5000
export HISTCONTROL=ignoreboth:erasedups
export HISTTIMEFORMAT="%d/%m/%y %T "
export HISTIGNORE="ls:pwd:clear:reset:[bf]g:exit"
shopt -s histappend

#xonsh
export FOREIGN_ALIASES_OVERRIDE=True

if [[ -z "$LC_EXTRATERM_COOKIE" ]]; then
  PROMPT_COMMAND="history -a;history -n;${PROMPT_COMMAND}"
fi

#Apply our completions last
export BASH_COMPLETION_COMPAT_DIR="/usr/local/etc/bash_completion.d"
[[ -r "/usr/local/etc/profile.d/bash_completion.sh" ]] && source "/usr/local/etc/profile.d/bash_completion.sh"

if [ "${UNAME}" != "Darwin" ]; then
  if [ -f "$([ -f /usr/local/bin/brew ] && brew --prefix)/etc/bash_c/usr/local/etc/profile.d/bashompletion.d/vagrant" ]; then
    source "$([ -f /usr/local/bin/brew ] && brew --prefix)/etc/bash_completion.d/vagrant"
  fi
fi

[ -f ~/.hub-completion.sh ] && source ~/.hub-completion.sh
[ -f ~/bin/completion-ruby/completion-ruby-all ] && source ~/bin/completion-ruby/completion-ruby-all
[ -f ~/.rbenv/shims/tmuxinator_completion ] && source ~/.rbenv/shims/tmuxinator_completion

if [[ -f ${HOME}/bin/setup_extraterm_bash.sh ]]; then
  if [[ -n "$LC_EXTRATERM_COOKIE" ]]; then
    source ${HOME}/bin/setup_extraterm_bash.sh
  fi
fi

[ -f ~/.fzf.bash ] && source ~/.fzf.bash
export FZF_DEFAULT_OPS="--extended"

mkdir -p "${HOME}/.bash_completion.d"
for i in $(ls -C1 ${HOME}/.bash_completion.d); do
    source "${HOME}/.bash_completion.d/${i}"
done

if command -v "pipenv" &> /dev/null; then
  source <(pipenv --completion)
fi

if command -v "golangci-lint" &> /dev/null; then
  source <(golangci-lint completion bash)
fi

if command -v "kubectl" &> /dev/null; then
  source <(kubectl completion bash)
fi

complete -C aws_completer aws
complete -F __start_kubectl k

# Golang
export PATH="/usr/local/go/bin:$PATH"
export GOPATH="/Users/spkane/dev/go/path"
GOROOT=$(go env GOROOT)
export GOROOT
ln -sfh "${GOROOT}" /Users/spkane/dev/go/root 2> /dev/null
sudo -n ln -sfh "${GOROOT}" /usr/local/go 2> /dev/null
export GOBIN="$GOPATH/bin"
export PATH="${GOBIN}:${PATH}"
export GOARCH=amd64
export GOOS=darwin
#export CGO_ENABLED=1

if command -v "fasd" &> /dev/null; then
  eval "$(fasd --init auto)"
fi

if command -v "direnv" &> /dev/null; then
  eval "$(direnv hook bash)"
fi

touch "${HOME}/.bashrc.personal"
for i in $(ls -C1 ${HOME}/.bashrc.personal*); do
    source "${i}"
done
