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
alias va=". .env/bin/activate.fish"
alias vd="deactivate"
alias cat="bat"
alias l="eza -l -a"
# alias docker-clean="docker stop $(docker ps -a -q) && docker rm -vf $(docker ps -aq) && docker rmi -f $(docker images -aq)"
alias at="alacritty-themes"
alias mkdir="mkdir -p"
alias gcm="bash /Users/duarteocarmo/commiter.sh"
alias pa="poetry shell"
alias pd="exit"


set PATH /usr/local/bin $PATH
thefuck --alias | source
source ~/.asdf/asdf.fish


set -gx ATUIN_NOBIND "true"
atuin init fish | source

# bind to ctrl-r in normal and insert mode, add any other bindings you want here too
bind \cr _atuin_search
bind -M insert \cr _atuin_search
