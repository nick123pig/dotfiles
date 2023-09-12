# ZSH History
HISTFILE=$HOME/.zhistory       # enable history saving on shell exit
setopt APPEND_HISTORY          # append rather than overwrite history file.
HISTSIZE=1200000               # lines of history to maintain memory
SAVEHIST=1000000               # lines of history to maintain in history file.
setopt HIST_EXPIRE_DUPS_FIRST  # allow dups, but expire old ones when I hit HISTSIZE
setopt EXTENDED_HISTORY        # save timestamp and runtime information
setopt SHARE_HISTORY

# ZSH Up/Down History
autoload -U up-line-or-beginning-search
autoload -U down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey "^[[A" up-line-or-beginning-search # Up
bindkey "^[[B" down-line-or-beginning-search # Down

# OS Specific
if [[ $(uname) == "Darwin" ]]; then
  # Load homebrew
  (echo; echo 'eval "$(/opt/homebrew/bin/brew shellenv)"') >> /Users/n/.zprofile
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

export GREP_OPTIONS='--color=auto'
export GREP_COLOR='100;7'
export PS1='%(?.%F{green}0.%F{red}%?)%f %B%F{240}%1~%f%b $ '

alias clearall='printf "\033c"'
alias ls='ls -G'
alias gb='git branch'
alias gbr='git branch -r'
alias gf='git fetch --all --prune'
alias gr='git rebase origin/master'
alias gs='git status'
alias gp='git stash;git pull'
alias gcm='git checkout master'
alias git_cleanup='git branch -r | awk '{print $1}' | egrep -v -f /dev/fd/0 <(git branch -vv | grep origin) | awk '{print $1}' | xargs git branch -d'
alias yubikey_change='gpg-connect-agent "scd serialno" "learn --force" /bye'
alias yubikey_unlock="gpg-connect-agent \"SCD CHECKPIN $(gpg-connect-agent 'scd serialno' /bye |head -1 |cut -d ' ' -f3)\" /bye"
alias gpg_kill='gpgconf --kill gpg-agent'

# Git Autocompletion
zstyle ':completion:*:*:git:*' script ~/.zsh/git-completion.bash
fpath=(~/.zsh $fpath)
autoload -Uz compinit && compinit

# GPG
export GPG_TTY=$TTY
function _gpg-agent_update-tty_preexec {
  gpg-connect-agent updatestartuptty /bye &>/dev/null
}
autoload -U add-zsh-hook
add-zsh-hook preexec _gpg-agent_update-tty_preexec
if [[ $(gpgconf --list-options gpg-agent 2>/dev/null | awk -F: '$1=="enable-ssh-support" {print $10}') = 1 ]]; then
  unset SSH_AGENT_PID
  if [[ "${gnupg_SSH_AUTH_SOCK_by:-0}" -ne $$ ]]; then
    export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"
  fi
fi

# SSH
if ! ps -ef | grep "[s]sh-agent" &>/dev/null; then
    echo Starting SSH Agent
    eval $(ssh-agent -s)
fi

source $HOME/.zsh/util_funcs.sh