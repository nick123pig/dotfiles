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
  eval "$(/opt/homebrew/bin/brew shellenv)"
  # Load homebrew completions
  FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"
fi

# load zsh completions
autoload -Uz compinit && compinit

export PS1='%(?.%F{green}0.%F{red}%?)%f %B%F{240}%1~%f%b $ '

source $HOME/.shell/aliases.sh

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

# Utilities
source $HOME/.shell/util_funcs.sh

# ASDF
if [[ -f "$HOME/.asdf/asdf.sh" ]]; then
  . "$HOME/.asdf/asdf.sh"
fi
