#     ____   ____   _____ _  _____   __  __          _____ 
#    |  _ \ / __ \ / ____( )/ ____| |  \/  |   /\   / ____|
#    | | | | |  | | |    |/| (___   | \  / |  /  \ | |     
#    | | | | |  | | |       \___ \  | |\/| | / /\ \| |     
#    | |__| | |__| | |____   ____) | | |  | |/ ____ \ |____ 
#    |_____/ \____/ \_____| |_____/  |_|  |_/_/    \_\_____|
#
# setup rosetta
/usr/sbin/softwareupdate --install-rosetta --agree-to-license

# install homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
export PATH="/opt/homebrew/bin:$PATH"


# install fish shell and update
echo /opt/homebrew/bin/fish | sudo tee -a /etc/shells
chsh -s /opt/homebrew/bin/fish
fish_add_path /opt/homebrew/bin
fish_update_completions


# install homebrew casks
brew install --cask appcleaner
brew install --cask arc
brew install --cask arc
brew install --cask bitwarden
brew install --cask caffeine
brew install --cask cap
brew install --cask cursor
brew install --cask cyberduck
brew install --cask db-browser-for-sqlite
brew install --cask discord
brew install --cask docker
brew install --cask firefox
brew install --cask font-commit-mono-nerd-font
brew install --cask font-iosevka
brew install --cask font-jetbrains-mono
brew install --cask github
brew install --cask google-chrome
brew install --cask handbrake
brew install --cask iina
brew install --cask imageoptim
brew install --cask itsycal
brew install --cask jordanbaird-ice
brew install --cask languagetool
brew install --cask logitech-g-hub
brew install --cask logitech-options
brew install --cask maestral
brew install --cask meetingbar
brew install --cask menubar-countdown
brew install --cask mimestream
brew install --cask mullvadvpn
brew install --cask ngrok
brew install --cask nordvpn
brew install --cask notion
brew install --cask notion-calendar
brew install --cask olama
brew install --cask ollama
brew install --cask pika
brew install --cask raycast
brew install --cask reader
brew install --cask rectangle
brew install --cask shottr
brew install --cask slack
brew install --cask spotify
brew install --cask stats
brew install --cask tableplus
brew install --cask telegram
brew install --cask the-unarchiver
brew install --cask ticktick
brew install --cask visual-studio-code
brew install --cask vlc
brew install --cask webtorrent
brew install --cask wezterm
brew install --cask whatsapp
brew install --cask zed
brew install --cask zettlr

# non brews
brew install asdf
brew install atuin
brew install awscurl
brew install bat
brew install cmake
brew install coreutils 
brew install cormacrelf/tap/dark-notify
brew install curl
brew install dark-notify
brew install direnv
brew install dive
brew install duckdb
brew install eza
brew install ffmpeg
brew install fish
brew install fzf
brew install gcc
brew install gh
brew install ghostty
brew install git
brew install git-lfs
brew install graphviz
brew install htop
brew install jordanbaird-ice
brew install jq
brew install just
brew install lazygit
brew install litestream
brew install lpeg
brew install lua
brew install luajit
brew install luarocks
brew install mysql
brew install neovim
brew install php
brew install pipx
brew install prettierd
brew install rclone
brew install ripgrep
brew install sqlite
brew install stripe
brew install tesseract
brew install thefuck
brew install tmux
brew install tree
brew install uv
brew install wget
brew install zig

# uv
echo 'uvx --generate-shell-completion fish | source' >> ~/.config/fish/config.fish

# asdf 
echo -e "\nsource "(brew --prefix asdf)"/libexec/asdf.fish" >> ~/.config/fish/config.fish
asdf plugin-add python
asdf plugin add golang https://github.com/asdf-community/asdf-golang.git
asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git
asdf install python latest
asdf install golang latest
asdf install nodejs latest
fish_update_completions

# fisher 
curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher
fisher install jethrokuan/z

# rust and cargo 
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
