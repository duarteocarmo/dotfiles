export ZSH="/Users/duartecarmo/.oh-my-zsh"
ZSH_THEME="mh"
plugins=(asdf zsh-z zsh-autosuggestions zsh-syntax-highlighting)

source $ZSH/oh-my-zsh.sh

alias brow='/usr/local/homebrew/bin/brew'
alias vi="nvim"
alias gst="git status"
alias ga="git add "
alias gc="git commit -m "
alias gp="git push"
alias tn="tmux new -s "
alias tl="tmux ls"
alias ta="tmux attach-session -t "
alias tk="tmux kill-server"
alias vi="nvim"
alias tree="tree -I __pycache__"
alias joplin="~/.joplin-bin/bin/joplin"
alias vc="python3 -m venv .env"
alias va=". .env/bin/activate"
alias vd="deactivate"
alias cat="bat"
# alias docker="podman"


# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/duartecarmo/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/duartecarmo/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/duartecarmo/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/duartecarmo/google-cloud-sdk/completion.zsh.inc'; fi

export PATH="$HOME/.poetry/bin:$PATH"
export PATH="$HOME/.emacs.d/bin:$PATH"

# bun completions
[ -s "/Users/duartecarmo/.bun/_bun" ] && source "/Users/duartecarmo/.bun/_bun"

# Bun
export BUN_INSTALL="/Users/duartecarmo/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"


export JAVA_HOME=/opt/homebrew/opt/openjdk/bin/java

# Created by `pipx` on 2022-12-19 20:02:26
export PATH="$PATH:/Users/duartecarmo/.local/bin"
