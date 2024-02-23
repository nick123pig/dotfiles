# GPG Init
if [ ! -f "$HOME/.gnupg/gpg-agent.conf" ]; then
    cp $HOME/.gnupg/gpg-agent.conf.default $HOME/.gnupg/gpg-agent.conf
    if [[ $(uname) == "Darwin" ]]; then
      echo "pinentry-program /opt/homebrew/bin/pinentry-mac" >> $HOME/.gnupg/gpg-agent.conf
    else
      echo "pinentry-program /usr/bin/pinentry-curses" >> $HOME/.gnupg/gpg-agent.conf
    fi
fi

# GPG
gpg-connect-agent updatestartuptty /bye &>/dev/null
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
