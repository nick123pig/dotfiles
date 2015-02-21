HISTFILE=$HOME/.zhistory       # enable history saving on shell exit
setopt APPEND_HISTORY          # append rather than overwrite history file.
HISTSIZE=1200000               # lines of history to maintain memory
SAVEHIST=1000000               # lines of history to maintain in history file.
setopt HIST_EXPIRE_DUPS_FIRST  # allow dups, but expire old ones when I hit HISTSIZE
setopt EXTENDED_HISTORY        # save timestamp and runtime information
setopt SHARE_HISTORY

source ~/.zsh_app_env_vars

export PS1='$ '
export EDITOR=nano
export GREP_OPTIONS='--color=auto' 
export GREP_COLOR='100;7'

alias ls='ls -G'

# git aliases
alias gitk='gitk 2>/dev/null'
alias gb='git branch'
alias gbr='git branch -r'
alias gf='git fetch --all --prune'
alias gr='git rebase origin/master'
alias gs='git status'
alias fixup='git commit -a --amend'
alias gcm='git checkout master'

eval "$(rbenv init -)"
