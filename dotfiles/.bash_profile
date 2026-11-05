# Login environment; inherited by interactive shells and other child processes.
if [[ $(uname) == "Darwin" ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

if [ -d "$HOME/.bin" ]; then
  PATH="$HOME/.bin:$PATH"
fi

if [ -d "$HOME/.local/bin" ]; then
  PATH="$HOME/.local/bin:$PATH"
fi

[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"

export PATH="$HOME/.pi/agent/bin:$PATH"
export DO_NOT_TRACK=1

# Login shells also need the interactive setup in .bashrc.
[ -r "$HOME/.bashrc" ] && . "$HOME/.bashrc"
