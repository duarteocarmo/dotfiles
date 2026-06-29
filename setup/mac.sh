#!/usr/bin/env bash
set -euo pipefail

DOTFILES_REPO="${DOTFILES_REPO:-git@github.com:duarteocarmo/dotfiles.git}"
DOTFILES_HTTPS_REPO="${DOTFILES_HTTPS_REPO:-https://github.com/duarteocarmo/dotfiles.git}"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"

TAPS=(
  anomalyco/tap
  charmbracelet/tap
  cormacrelf/tap
  epk/epk
  fastrepl/fastrepl
  gitpod-io/tap
  localstack/tap
  nikitabobko/tap
  popcorn-official/popcorn-desktop
  saihgupr/notificli
  steipete/tap
  xykong/tap
  zackriya-solutions/meetily
)

FORMULAE=(
  act
  aria2
  ast-grep
  atuin
  awscli
  awscurl
  bat
  biome
  btop
  cdk8s
  cmake
  cocoapods
  container
  coreutils
  curl
  difftastic
  direnv
  dive
  duckdb
  duti
  elixir
  emscripten
  espeak-ng
  eza
  fastlane
  ffmpeg
  ffuf
  fish
  fzf
  git
  git-filter-repo
  git-lfs
  git-xet
  glab
  grip
  jq
  lazygit
  luarocks
  lychee
  markdownlint-cli2
  mosh
  murex
  mysql
  neovim
  openfst
  openjdk
  pandoc
  php
  pipx
  pnpm
  portaudio
  postgresql@14
  postgresql@17
  prettierd
  rclone
  ripgrep
  rsync
  sshuttle
  stunnel
  stylua
  swiftformat
  taplo
  telnet
  tesseract
  tmux
  trash
  tree
  wget
  yt-dlp
  zig
  zoxide
)

CASKS=(
  bitwarden
  chatgpt
  chatwise
  codex
  codex-app
  cursor
  cyberduck
  daisydisk
  db-browser-for-sqlite
  discord
  dockdoor
  element
  epk/epk/font-sf-mono-nerd-font
  font-comic-mono
  font-commit-mono-nerd-font
  font-departure-mono-nerd-font
  font-fira-code
  font-geist-mono
  font-geist-mono-nerd-font
  font-hack-nerd-font
  font-ia-writer-duo
  font-ia-writer-mono
  font-ia-writer-quattro
  font-ibm-plex-mono
  font-inter
  font-iosevka
  font-iosevka-nerd-font
  font-jetbrains-mono
  font-lora
  font-noto-nerd-font
  font-noto-sans-mono
  font-sf-pro
  gcloud-cli
  google-chrome
  grandperspective
  handy
  helium
  hermes
  iina
  imageoptim
  itsycal
  kitty
  languagetool-desktop
  mactex
  macwhisper
  menubar-countdown
  mimestream
  netnewswire
  nextcloud
  nordvpn
  notion
  notion-calendar
  obsidian
  onyx
  orbstack
  pika
  pingid
  raycast
  shortcat
  shottr
  slack
  spotify
  stats
  tailscale-app
  telegram
  ticktick
  transmit
  webtorrent
  zed
)


log() { printf '\n==> %s\n' "$*"; }
need_cmd() { command -v "$1" >/dev/null 2>&1; }

run_optional() {
  local name="$1"
  shift

  if "$@"; then
    log "$name done."
    return 0
  fi

  log "$name skipped or failed."
}

setup_xcode_tools() {
  if xcode-select -p >/dev/null 2>&1; then
    return 0
  fi

  xcode-select --install || true
  log "Command Line Tools installer opened. Re-run this script after it finishes if Homebrew fails."
}

install_rosetta() {
  if [[ "$(uname -m)" != "arm64" ]]; then
    return 0
  fi

  /usr/bin/pgrep oahd >/dev/null 2>&1 && return 0
  sudo /usr/sbin/softwareupdate --install-rosetta --agree-to-license || true
}

setup_homebrew_path() {
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
}

install_homebrew() {
  setup_homebrew_path
  if need_cmd brew; then
    return 0
  fi

  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  setup_homebrew_path
}

install_taps() {
  local tap
  for tap in "${TAPS[@]}"; do
    brew tap "$tap" || true
  done
}

install_formulae() {
  brew update

  local formula
  for formula in "${FORMULAE[@]}"; do
    brew install "$formula" || true
  done
}

install_casks() {
  local cask
  for cask in "${CASKS[@]}"; do
    brew install --cask "$cask" || true
  done
}

clone_dotfiles() {
  if git -C "$HOME" remote get-url origin 2>/dev/null | grep -q "duarteocarmo/dotfiles"; then
    log "Dotfiles already checked out in $HOME."
    return 0
  fi

  if [[ ! -d "$DOTFILES_DIR/.git" ]]; then
    git clone "$DOTFILES_REPO" "$DOTFILES_DIR" || git clone "$DOTFILES_HTTPS_REPO" "$DOTFILES_DIR"
  fi

  rsync -a --exclude '.git' --exclude '.DS_Store' "$DOTFILES_DIR/" "$HOME/"
}

install_mise() {
  export PATH="$HOME/.local/bin:$PATH"

  if ! need_cmd mise; then
    curl https://mise.run | sh
    export PATH="$HOME/.local/bin:$PATH"
  fi

  if [[ ! -f "$HOME/.config/mise/config.toml" ]]; then
    log "No mise config found at ~/.config/mise/config.toml; skipping mise tools."
    return 0
  fi

  mise trust "$HOME/.config/mise/config.toml" || true
  mise install -y
}

setup_fish() {
  mkdir -p "$HOME/.config/fish" "$HOME/.codex" "$HOME/.claude" "$HOME/.config/opencode"
  touch "$HOME/.config/fish/secrets.fish"
  chmod 600 "$HOME/.config/fish/secrets.fish"

  local fish_path
  fish_path="$(command -v fish)"

  if ! grep -qF "$fish_path" /etc/shells; then
    echo "$fish_path" | sudo tee -a /etc/shells >/dev/null
  fi

  if [[ "${SHELL:-}" != "$fish_path" ]]; then
    chsh -s "$fish_path" "$USER" || true
  fi

  fish -c 'fish_add_path /opt/homebrew/bin ~/.local/bin ~/.local/share/mise/shims; fish_update_completions' || true

  if [[ -f "$HOME/.config/fish/fish_plugins" ]]; then
    fish -c 'if not type -q fisher; curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source; end; fisher update' || true
  fi
}

setup_atuin_history() {
  mkdir -p "$HOME/.local/share/atuin"

  if [[ -f "$HOME/Nextcloud/dots/atuin_key" && ! -f "$HOME/.local/share/atuin/key" ]]; then
    cp "$HOME/Nextcloud/dots/atuin_key" "$HOME/.local/share/atuin/key"
    chmod 600 "$HOME/.local/share/atuin/key"
  fi

  [[ -f "$HOME/.zsh_history" ]] && atuin import zsh || true
  [[ -f "$HOME/.bash_history" ]] && atuin import bash || true
  [[ -d "$HOME/.local/share/fish" || -f "$HOME/.local/share/fish/fish_history" ]] && atuin import fish || true

  atuin sync || true
  atuin status || true
}

setup_git() {
  git lfs install || true
}

main() {
  setup_xcode_tools
  run_optional "Rosetta" install_rosetta
  install_homebrew
  log "Homebrew ready."

  install_taps
  log "Homebrew taps ready."

  install_formulae
  log "Homebrew formulae ready."

  install_casks
  log "Homebrew casks ready."

  clone_dotfiles
  log "Dotfiles ready."

  install_mise
  log "mise and mise tools ready."

  run_optional "fish" setup_fish
  run_optional "Atuin history" setup_atuin_history
  run_optional "git" setup_git

  brew cleanup || true

  log "Done. Open a new terminal. If Atuin did not sync, run: atuin login && atuin sync"
}

main "$@"
