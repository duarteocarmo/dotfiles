export ZSH="/Users/duarteocarmo/.oh-my-zsh"
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

ZSH_THEME="mh"
plugins=(z zsh-autosuggestions zsh-syntax-highlighting poetry asdf)

source $ZSH/oh-my-zsh.sh

alias brow='/usr/local/homebrew/bin/brew'
alias vi="nvim"
alias gst="git status"
alias ga="git add "
alias gc="git commit -m "
alias gp="git push"
# alias tn="zellij -s"
# alias tl="zellij ls"
# alias ta="zellij attach"
# alias tk="zellij ka -y && zellij da -y"
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
alias l="eza -l -a"
# alias docker-clean="docker stop $(docker ps -a -q) && docker rm -vf $(docker ps -aq) && docker rmi -f $(docker images -aq)"
alias at="alacritty-themes"
alias mkdir="mkdir -p"
alias gcm="bash /Users/duarteocarmo/commiter.sh"
alias pa="poetry shell"
alias pd="exit"
# alias docker="podman"




# >>> juliaup initialize >>>

# !! Contents within this block are managed by juliaup !!

path=('/Users/duarteocarmo/.juliaup/bin' $path)
export PATH

# <<< juliaup initialize <<<

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/duarteocarmo/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/duarteocarmo/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/duarteocarmo/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/duarteocarmo/google-cloud-sdk/completion.zsh.inc'; fi

# bun completions
[ -s "/Users/duarteocarmo/.bun/_bun" ] && source "/Users/duarteocarmo/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# pnpm
export PNPM_HOME="/Users/duarteocarmo/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end
#
#
export PATH="/Users/duarteocarmo/.local/bin:$PATH"


source /Users/duarteocarmo/.config/broot/launcher/bash/br
eval "$(direnv hook zsh)"
. "$HOME/.cargo/env"

eval "$(atuin init zsh --disable-up-arrow)"
export EDITOR=nvim

# Created by `pipx` on 2024-06-12 09:07:35
export PATH="$PATH:/Users/duarteocarmo/.local/bin"


