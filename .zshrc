HISTFILE=$HOME/.zhistory       # enable history saving on shell exit
setopt APPEND_HISTORY          # append rather than overwrite history file.
HISTSIZE=1200000               # lines of history to maintain memory
SAVEHIST=1000000               # lines of history to maintain in history file.
setopt HIST_EXPIRE_DUPS_FIRST  # allow dups, but expire old ones when I hit HISTSIZE
setopt EXTENDED_HISTORY        # save timestamp and runtime information
setopt SHARE_HISTORY

source ~/.zsh_app_env_vars

export PS1='$ '
export GREP_OPTIONS='--color=auto'
export GREP_COLOR='100;7'
fpath=(/Users/nick/.zsh/zsh-completions/src $fpath)
alias ls='ls -G'
alias gb='git branch'
alias gbr='git branch -r'
alias gf='git fetch --all --prune'
alias gr='git rebase origin/master'
alias gs='git status'
alias gp='git stash;git pull'
alias gcm='git checkout master'
alias git_cleanup='git branch -r | awk '{print $1}' | egrep -v -f /dev/fd/0 <(git branch -vv | grep origin) | awk '{print $1}' | xargs git branch -d'
alias oldscheduled='ssh -i ~/.ssh/help.kitcheck.com.pem ec2-user@54.82.67.92'
alias scheduled='ssh -i ~/.ssh/help.kitcheck.com.pem ubuntu@ec2-52-1-116-208.compute-1.amazonaws.com'
alias dashboard='ssh kitcheck@dashboard.kitcheck.com'
alias dlscheduled='scp -i ~/.ssh/help.kitcheck.com.pem ec2-user@54.82.67.92:'
alias updateprodcopy='ruby /Users/nick/kitcheck/support-tools/update_prodcopy.rb'
export PATH="$HOME/.bin:$PATH"

export PATH="$PATH:/usr/local/lib/node_modules"
source $(brew --prefix nvm)/nvm.sh

export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init - zsh --no-rehash)"
source ~/.bash_profile

function up() {
  i=$1
  while [ $i -gt 0 ]
  do
     cd ..
     i=$(($i - 1))
  done
}
