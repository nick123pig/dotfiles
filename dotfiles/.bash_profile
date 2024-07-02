source $HOME/.bashrc
source $HOME/.shell/interactive.sh

bind '"\e[A": history-search-backward'
bind '"\e[B": history-search-forward'

# bash autocomplete
if [[ $(uname) == "Darwin" ]]; then
    if [ -f $(brew --prefix)/etc/bash_completion ]; then
        . $(brew --prefix)/etc/bash_completion
    fi
else
    source /etc/profile.d/bash_completion.sh
fi