HISTFILE=$HOME/.zhistory       # enable history saving on shell exit
setopt APPEND_HISTORY          # append rather than overwrite history file.
HISTSIZE=1200000               # lines of history to maintain memory
SAVEHIST=1000000               # lines of history to maintain in history file.
setopt HIST_EXPIRE_DUPS_FIRST  # allow dups, but expire old ones when I hit HISTSIZE
setopt EXTENDED_HISTORY        # save timestamp and runtime information
setopt SHARE_HISTORY

export ZSH="/Users/n/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(git ssh-agent gpg-agent)
source $ZSH/oh-my-zsh.sh
export GREP_OPTIONS='--color=auto'
export GREP_COLOR='100;7'
export GPG_TTY=$(tty)

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
alias yubikey='gpg-connect-agent "scd serialno" "learn --force" /bye'
alias gpg_unlock="gpg-connect-agent \"SCD CHECKPIN $(gpg-connect-agent 'scd serialno' /bye |head -1 |cut -d ' ' -f3)\" /bye"
 
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

. $(brew --prefix asdf)/asdf.sh
