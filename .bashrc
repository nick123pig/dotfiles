# OS Specific
if [[ $(uname) == "Darwin" ]]; then
  # Load homebrew
  eval "$(/opt/homebrew/bin/brew shellenv)"
  # Load bash completion
  [ -f /usr/local/etc/bash_completion ] && . /usr/local/etc/bash_completion
fi

bind '"\e[A": history-search-backward'
bind '"\e[B": history-search-forward'

source $HOME/.shell/aliases.sh

export PS1='\e[97m\h\e[00m\e[01;31m$(code=${?##0};echo ${code:+" "${code}})\e[00m \W\e[00m \e[97m\\$ \e[00m'

# Eternal bash history.
# ---------------------
# Undocumented feature which sets the size to "unlimited".
# http://stackoverflow.com/questions/9457233/unlimited-bash-history
export HISTFILESIZE=
export HISTSIZE=
export HISTTIMEFORMAT="[%F %T] "
# Change the file location because certain bash sessions truncate .bash_history file upon close.
# http://superuser.com/questions/575479/bash-history-truncated-to-500-lines-on-each-login
export HISTFILE=~/.bash_eternal_history
# Force prompt to write history after every command.
# http://superuser.com/questions/20900/bash-history-loss
PROMPT_COMMAND="history -a; $PROMPT_COMMAND"
