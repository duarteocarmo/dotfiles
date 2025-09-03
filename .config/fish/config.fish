if status is-interactive
    # Commands to run in interactive sessions can go here
end


alias brow='/usr/local/homebrew/bin/brew'
alias vi="nvim"
alias gst="git status"
alias ga="git add "
alias gc="git commit -m "
alias gp="git push"
alias gpc="git push origin (git branch --show-current)"
alias gcz="npx cz"
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
alias vc="python -m venv .env"
function va
    if test -f poetry.lock
        poetry shell
        return
    end

    if test -d .venv
        source .venv/bin/activate.fish
    else if test -d .env
        source .env/bin/activate.fish
    else
        echo "No .venv, .env, or poetry.lock found"
    end
end
alias vd="deactivate"
alias cat="bat"
alias l="eza -l -a"
# alias docker-clean="docker stop $(docker ps -a -q) && docker rm -vf $(docker ps -aq) && docker rmi -f $(docker images -aq)"
alias at="alacritty-themes"
alias mkdir="mkdir -p"
alias gcm="bash /Users/duarteocarmo/commiter.sh"
alias pa="poetry shell"
alias pd="exit"
alias psh="poetry shell"



set PATH /usr/local/bin $PATH
thefuck --alias | source


set -gx ATUIN_NOBIND "true"
atuin init fish | source

# bind to ctrl-r in normal and insert mode, add any other bindings you want here too
bind \cr _atuin_search
bind -M insert \cr _atuin_search

source /opt/homebrew/opt/asdf/libexec/asdf.fish
uvx --generate-shell-completion fish | source

set fish_greeting

# Created by `pipx` on 2025-01-02 13:49:01
set PATH $PATH /Users/duarteocarmo/.local/bin

set -gx EDITOR nvim
set -gx VISUAL nvim

# pnpm
set -gx PNPM_HOME "/Users/duarteocarmo/Library/pnpm"
if not string match -q -- $PNPM_HOME $PATH
  set -gx PATH "$PNPM_HOME" $PATH
end
# pnpm end

# Added by LM Studio CLI (lms)
set -gx PATH $PATH /Users/duarteocarmo/.lmstudio/bin
# End of LM Studio CLI section


# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
source ~/.orbstack/shell/init2.fish 2>/dev/null || :

# bun
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH
fish_add_path $HOME/.local/bin





# The next line updates PATH for the Google Cloud SDK.
if [ -f '/opt/homebrew/share/google-cloud-sdk/path.fish.inc' ]; . '/opt/homebrew/share/google-cloud-sdk/path.fish.inc'; end
