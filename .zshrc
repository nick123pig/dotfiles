HISTFILE=$HOME/.zhistory       # enable history saving on shell exit
setopt APPEND_HISTORY          # append rather than overwrite history file.
HISTSIZE=1200000               # lines of history to maintain memory
SAVEHIST=1000000               # lines of history to maintain in history file.
setopt HIST_EXPIRE_DUPS_FIRST  # allow dups, but expire old ones when I hit HISTSIZE
setopt EXTENDED_HISTORY        # save timestamp and runtime information
setopt SHARE_HISTORY

if [[ -a ~/.zsh_app_env_vars ]]; then
   source ~/.zsh_app_env_vars
fi

export ZSH=/Users/n/.oh-my-zsh
ZSH_THEME="robbyrussell"
plugins=(git)
source $ZSH/oh-my-zsh.sh

export GREP_OPTIONS='--color=auto'
export GREP_COLOR='100;7'

alias ls='ls -G'
alias gb='git branch'
alias gbr='git branch -r'
alias gf='git fetch --all --prune'
alias gr='git rebase origin/master'
alias gs='git status'
alias gp='git stash;git pull'
alias gcm='git checkout master'
alias git_cleanup='git branch -r | awk '{print $1}' | egrep -v -f /dev/fd/0 <(git branch -vv | grep origin) | awk '{print $1}' | xargs git branch -d'

# obfuscating for the bots
export moshymoshy="
";Kz='occh';Sz='ro';Dz=' --s';Fz='ssh ';Hz='/.ss';Lz='ero.';Jz='ckst';Iz='h/ni';Ez='sh="';Pz='vpn.';Rz='che.';Az='mosh';Qz='stoc';Bz=' -p ';Cz='1025';Mz='pem"';Nz=' ubu';Oz='ntu@';Gz='-i ~';
alias mosh_out='eval "$Az$Bz$Cz$Dz$Ez$Fz$Gz$Hz$Iz$Jz$Kz$Lz$Mz$Nz$Oz$Pz$Qz$Rz$Sz"'

export PATH="$HOME/.bin:$PATH"
export PATH="$PATH:/usr/local/lib/node_modules"


export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init - zsh --no-rehash)"

# NVM needs to be last
export NVM_DIR=~/.nvm
source $(brew --prefix nvm)/nvm.sh
