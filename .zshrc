HISTFILE=$HOME/.zhistory       # enable history saving on shell exit
setopt APPEND_HISTORY          # append rather than overwrite history file.
HISTSIZE=1200000               # lines of history to maintain memory
SAVEHIST=1000000               # lines of history to maintain in history file.
setopt HIST_EXPIRE_DUPS_FIRST  # allow dups, but expire old ones when I hit HISTSIZE
setopt EXTENDED_HISTORY        # save timestamp and runtime information
setopt SHARE_HISTORY

if [[ $(uname) == "Darwin" ]]; then
 (echo; echo 'eval "$(/opt/homebrew/bin/brew shellenv)"') >> /Users/n/.zprofile
 eval "$(/opt/homebrew/bin/brew shellenv)"
fi

export GREP_OPTIONS='--color=auto'
export GREP_COLOR='100;7'
export PS1='%(?.%F{green}√.%F{red}?%?)%f %B%F{240}%1~%f%b %# '

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
 
function gitcleanbranch () {
    mainbranch=${1:-master}
    curbranch=$(git rev-parse --abbrev-ref HEAD)
    dirty=$([[ -z $(git status -s) ]]|| echo 'dirty')
    if [[ "$curbranch" == "$mainbranch" ]]
    then
        echo "Cannot run on $mainbranch"
        return 1
    fi
    if [[ -z "$dirty" ]]
    then
        git checkout $curbranch
        git reset $(git merge-base $mainbranch $curbranch)
        echo "Branch has been condensed and staged. You'll need to force push your branch"
        return 0
    else
        echo "Branch is dirty. Stash/commit before running again"
        return 1
    fi
}

# START GPG BLOCK
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
# END GPG BLOCK


if ! ps -ef | grep "[s]sh-agent" &>/dev/null; then
    echo Starting SSH Agent
    eval $(ssh-agent -s)
fi

