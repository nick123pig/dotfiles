# Install Kitty's terminfo and shell integration on SSH destinations.
# Keep ordinary OpenSSH outside Kitty; `command ssh` bypasses this alias.
if [[ -n "$KITTY_WINDOW_ID" ]] && command -v kitten >/dev/null 2>&1; then
    alias ssh='kitten ssh'
fi

alias clearall='printf "\033c"'
alias ls='ls -G'
alias gb='git branch'
alias gbr='git branch -r'
alias gf='git fetch --all --prune'
alias gr='git rebase origin/master'
alias gs='git status'
alias gp='git stash;git pull'
alias gcm='git checkout master'
alias yubikey_change='gpg-connect-agent "scd serialno" "learn --force" /bye'
alias yubikey_unlock="gpg-connect-agent \"SCD CHECKPIN $(gpg-connect-agent 'scd serialno' /bye |head -1 |cut -d ' ' -f3)\" /bye"
alias gpg_kill='gpgconf --kill gpg-agent'

export GREP_OPTIONS='--color=auto'
export GREP_COLOR='100;7'
export EDITOR='vim'

if [[ $(uname) == "Darwin" ]]; then
    alias tailscale="/Applications/Tailscale.app/Contents/MacOS/Tailscale"
fi