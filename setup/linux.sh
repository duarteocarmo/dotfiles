#!/usr/bin/env bash
set -euo pipefail

# Minimal Ubuntu setup (CLI-focused).
# Tweak the lists below, then run:
#   bash setup/linux.sh

APT_PACKAGES=(
  ca-certificates
  curl
  wget
  unzip
  tar
  git
  fish
  tmux
  fzf
  ripgrep
  jq
  direnv
  zoxide
  eza
  bat
  btop
  tree
  sqlite3
  build-essential
  pkg-config
  cmake
)

MISE_TOOLS=(
  uv@latest
  node@22.20.0
  bun@latest
  go@1.22.4
)

FISH_CONFIG="$(cat <<'FISH'
if status is-interactive
end

fish_add_path $HOME/.local/bin

set -gx EDITOR nvim
set -gx VISUAL nvim

alias vi=nvim
alias l="eza -l -a"
if type -q bat
    alias cat=bat
else if type -q batcat
    alias cat=batcat
end
alias gst="git status"

set -gx ATUIN_NOBIND true
if type -q atuin
    atuin init fish | source
    bind \cr _atuin_search
    bind -M insert \cr _atuin_search
end

if type -q zoxide
    zoxide init fish | source
end

if type -q mise
    mise activate fish | source
end
FISH
)"

log() { printf '%s\n' "$*"; }
need_cmd() { command -v "$1" >/dev/null 2>&1; }

ensure_sudo() {
  if ! need_cmd sudo; then
    log "sudo not found"
    exit 1
  fi
  sudo -v
}

apt_install() {
  ensure_sudo
  sudo apt-get update -y
  sudo apt-get upgrade -y
  sudo apt-get install -y "${APT_PACKAGES[@]}"
  sudo apt-get autoremove -y
  sudo apt-get clean
}

install_mise() {
  if need_cmd mise; then
    return 0
  fi
  curl -fsSL https://mise.jdx.dev/install.sh | sh
  export PATH="$HOME/.local/bin:$PATH"
}

mise_install_tools() {
  export PATH="$HOME/.local/bin:$PATH"
  mise install "${MISE_TOOLS[@]}"
  mise use -g "${MISE_TOOLS[@]}"
}

install_neovim_nightly() {
  local arch
  arch="$(uname -m)"
  if [[ "$arch" != "x86_64" ]]; then
    log "Skipping neovim nightly (unsupported arch: $arch)."
    log "Edit install_neovim_nightly() if you want a different install method."
    return 0
  fi

  mkdir -p "$HOME/.local/bin"
  curl -fsSL -o "$HOME/.local/bin/nvim" \
    https://github.com/neovim/neovim/releases/download/nightly/nvim-linux-x86_64.appimage
  chmod +x "$HOME/.local/bin/nvim"
}

install_atuin() {
  if need_cmd atuin; then
    return 0
  fi

  if apt-cache show atuin >/dev/null 2>&1; then
    ensure_sudo
    sudo apt-get install -y atuin
    return 0
  fi

  # Fallback. If this ever changes, tweak the URL.
  curl -fsSL https://setup.atuin.sh | sh
  export PATH="$HOME/.local/bin:$PATH"
}

install_lazygit() {
  if need_cmd lazygit; then
    return 0
  fi

  local arch
  arch="$(uname -m)"
  case "$arch" in
    x86_64) arch="x86_64" ;;
    aarch64|arm64) arch="arm64" ;;
    *)
      log "Skipping lazygit (unsupported arch: $arch)."
      return 0
      ;;
  esac

  local version
  version="$(curl -fsSL https://api.github.com/repos/jesseduffield/lazygit/releases/latest | grep -Po '\"tag_name\": *\"v\\K[^\"]*' || true)"
  if [[ -z "${version}" ]]; then
    log "Could not resolve lazygit version"
    return 1
  fi

  local tmpdir
  tmpdir="$(mktemp -d)"
  curl -fsSL -o "$tmpdir/lazygit.tar.gz" \
    "https://github.com/jesseduffield/lazygit/releases/download/v${version}/lazygit_${version}_Linux_${arch}.tar.gz"
  tar -xzf "$tmpdir/lazygit.tar.gz" -C "$tmpdir" lazygit
  ensure_sudo
  sudo install "$tmpdir/lazygit" -D -t /usr/local/bin/
  rm -rf "$tmpdir"
}

setup_fish() {
  mkdir -p "$HOME/.config/fish"

  # Keep the generated config isolated and easy to remove.
  mkdir -p "$HOME/.config/fish/conf.d"
  printf '%s\n' "$FISH_CONFIG" >"$HOME/.config/fish/conf.d/00-machine-setup.fish"

  ensure_sudo
  local fish_path
  fish_path="$(command -v fish)"
  if ! grep -qF "$fish_path" /etc/shells; then
    echo "$fish_path" | sudo tee -a /etc/shells >/dev/null
  fi

  if [[ "${SHELL:-}" != "$fish_path" ]]; then
    chsh -s "$fish_path" "$USER" || true
  fi
}

main() {
  export DEBIAN_FRONTEND=noninteractive

  apt_install
  install_mise
  mise_install_tools
  install_neovim_nightly
  install_atuin
  install_lazygit
  setup_fish

  log "Done."
  log "Open a new terminal (or run: exec fish) to start using fish."
}

main "$@"
