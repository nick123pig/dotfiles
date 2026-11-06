# Interactive setup belongs here for both login and non-login shells.
[[ $- == *i* ]] || return

# Load bash completion once.
if [[ -z ${BASH_COMPLETION_VERSINFO+x} ]]; then
  if [[ $(uname) == "Darwin" ]]; then
    if command -v brew >/dev/null 2>&1; then
      completion_file="$(brew --prefix)/etc/bash_completion"
      [ -r "$completion_file" ] && . "$completion_file"
      unset completion_file
    fi
  else
    [ -r /etc/profile.d/bash_completion.sh ] && . /etc/profile.d/bash_completion.sh
  fi
fi

# Load zoxide
if [ -x "$(command -v zoxide)" ]; then
  eval "$(zoxide init bash)"
fi

set -o vi

if [[ -o emacs || -o vi ]]; then
  bind '"\e[A": history-search-backward'
  bind '"\e[B": history-search-forward'
fi

source "$HOME/.shell/aliases.sh"

export PS1='[\h] $? \$ '

# external bash history
export HISTFILESIZE=
export HISTSIZE=
export HISTTIMEFORMAT="[%F %T] "
export HISTFILE=~/.bash_eternal_history
export HISTCONTROL=ignorespace
PROMPT_COMMAND="history -a; $PROMPT_COMMAND"

# Agent sockets, pinentry TTY, utilities, and interactive tool setup.
source "$HOME/.shell/interactive.sh"
