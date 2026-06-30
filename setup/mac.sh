#!/usr/bin/env bash
set -euo pipefail

export NONINTERACTIVE=1
export HOMEBREW_NO_ENV_HINTS=1

DOTFILES_REPO="${DOTFILES_REPO:-git@github.com:duarteocarmo/dotfiles.git}"
DOTFILES_HTTPS_REPO="${DOTFILES_HTTPS_REPO:-https://github.com/duarteocarmo/dotfiles.git}"
DOTFILES_BRANCH="${DOTFILES_BRANCH:-master}"
RESET_DOTFILES=0
RESET_MISE=0

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
  cormacrelf/tap/dark-notify
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
  codex
  codex-app
  cursor
  cyberduck
  daisydisk
  db-browser-for-sqlite
  discord
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
  font-maple-mono-nf
  font-noto-nerd-font
  font-noto-sans-mono
  font-sf-pro
  gcloud-cli
  google-chrome
  grandperspective
  handy
  helium-browser
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
  ticktick
  transmit
  webtorrent
  zed
)


log() { printf '\n==> %s\n' "$*"; }
need_cmd() { command -v "$1" >/dev/null 2>&1; }

usage() {
  cat <<'EOF'
Usage: setup/mac.sh [options]

Options:
  --reset-dotfiles  Force $HOME to match origin/master for tracked dotfiles.
                    Also removes untracked, non-ignored files inside the repo.
  --reset-mise      Remove mise installs/cache before reinstalling from dots config.
  -h, --help        Show this help.
EOF
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --reset-dotfiles) RESET_DOTFILES=1 ;;
      --reset-mise) RESET_MISE=1 ;;
      -h|--help) usage; exit 0 ;;
      *) log "Unknown option: $1"; usage; exit 1 ;;
    esac
    shift
  done
}

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

install_formulae() {
  brew update

  local formula
  for formula in "${FORMULAE[@]}"; do
    brew install --yes "$formula" || true
  done
}

install_casks() {
  local cask
  for cask in "${CASKS[@]}"; do
    brew install --cask --yes "$cask" || true
  done
}

fetch_dotfiles() {
  if ! git -C "$HOME" fetch origin "$DOTFILES_BRANCH"; then
    git -C "$HOME" remote set-url origin "$DOTFILES_HTTPS_REPO"
    git -C "$HOME" fetch origin "$DOTFILES_BRANCH"
  fi
}

clone_dotfiles() {
  if git -C "$HOME" remote get-url origin 2>/dev/null | grep -q "duarteocarmo/dotfiles"; then
    fetch_dotfiles
    if [[ "$RESET_DOTFILES" == "1" ]]; then
      git -C "$HOME" reset --hard "origin/$DOTFILES_BRANCH"
      git -C "$HOME" clean -fd
    else
      git -C "$HOME" pull --ff-only || true
    fi
    log "Dotfiles ready in $HOME."
    return 0
  fi

  if [[ -d "$HOME/.git" ]]; then
    log "$HOME already has a different git repo; skipping dotfiles clone."
    return 1
  fi

  git -C "$HOME" init
  git -C "$HOME" remote add origin "$DOTFILES_REPO" || git -C "$HOME" remote set-url origin "$DOTFILES_HTTPS_REPO"
  fetch_dotfiles
  git -C "$HOME" checkout -B "$DOTFILES_BRANCH" "origin/$DOTFILES_BRANCH"
}

install_mise() {
  export PATH="$HOME/.local/bin:$PATH"

  if [[ "$RESET_MISE" == "1" ]]; then
    rm -rf "$HOME/.local/share/mise" "$HOME/.cache/mise"
  fi

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

  if ! dscl . -read "/Users/$USER" UserShell 2>/dev/null | grep -qF "$fish_path"; then
    sudo dscl . -create "/Users/$USER" UserShell "$fish_path"
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

  atuin sync -f || true
  atuin status || true
}

setup_git() {
  git lfs install || true
}

main() {
  parse_args "$@"

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

  log "Done. Open a new terminal. If Atuin did not sync, run: atuin login -u <username> && atuin sync -f"
}

main "$@"
