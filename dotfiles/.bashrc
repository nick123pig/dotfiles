# OS Specific
if [[ $(uname) == "Darwin" ]]; then
  # Load homebrew
  eval "$(/opt/homebrew/bin/brew shellenv)"
  # Load bash completion
  [ -f /usr/local/etc/bash_completion ] && . /usr/local/etc/bash_completion
fi

# local bin
if [ -d "$HOME/.bin" ]; then
  PATH="$HOME/.bin:$PATH"
fi

# Load zoxide
if [ -x "$(command -v zoxide)" ]; then
  eval "$(zoxide init bash)"
fi

bind '"\e[A": history-search-backward'
bind '"\e[B": history-search-forward'

source $HOME/.shell/aliases.sh

export PS1='[\h] $? \$ '

# GPG
GPG_TTY=$(tty)
export GPG_TTY

# external bash history
export HISTFILESIZE=
export HISTSIZE=
export HISTTIMEFORMAT="[%F %T] "
export HISTFILE=~/.bash_eternal_history
PROMPT_COMMAND="history -a; $PROMPT_COMMAND"

# Random
export DO_NOT_TRACK=1

