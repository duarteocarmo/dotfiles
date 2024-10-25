# install homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# install homebrew casks
brew install --cask appcleaner
brew install --cask bitwarden
brew install --cask caffeine
brew install --cask cursor
brew install --cask cyberduck
brew install --cask db-browser-for-sqlite
brew install --cask discord
brew install --cask docker
brew install --cask firefox
brew install --cask font-iosevka
brew install --cask font-jetbrains-mono
brew install --cask github
brew install --cask google-chrome
brew install --cask reader
brew install --cask handbrake
brew install --cask iina
brew install --cask imageoptim
brew install --cask itsycal
brew install --cask jordanbaird-ice
brew install --cask languagetool
brew install --cask logitech-g-hub
brew install --cask maestral
brew install --cask meetingbar
brew install --cask menubar-countdown
brew install --cask mimestream
brew install --cask cap
brew install --cask mullvadvpn
brew install --cask ngrok
brew install --cask nordvpn
brew install --cask notion
brew install --cask notion-calendar
brew install --cask olama
brew install --cask pika
brew install --cask raycast
brew install --cask rectangle
brew install --cask shottr
brew install --cask slack
brew install --cask spotify
brew install --cask stats
brew install --cask tableplus
brew install --cask telegram
brew install --cask ticktick
brew install --cask visual-studio-code
brew install --cask vlc
brew install --cask webtorrent
brew install --cask wezterm
brew install --cask whatsapp
brew install --cask zed
brew install --cask zettlr

# non brews
brew install jordanbaird-ice
brew install neovim

# install fish shell 
brew install fish

# asdf 
brew install coreutils curl git
echo -e "\nsource "(brew --prefix asdf)"/libexec/asdf.fish" >> ~/.config/fish/config.fish

