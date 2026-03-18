#!/usr/bin/env bash
set -euo pipefail

# Minimal Linux setup for coding with pi.
# Installs: git, curl, tmux, ripgrep, uv, node, neovim, gh, pi
#   bash setup/linux-minimal.sh

APT_PACKAGES=(
  ca-certificates
  curl
  wget
  unzip
  git
  tmux
  ripgrep
  jq
  build-essential
)

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
  sudo apt-get install -y "${APT_PACKAGES[@]}"
  sudo apt-get clean
  log "APT packages installed."
}

install_uv() {
  if need_cmd uv; then
    log "uv already installed."
    return 0
  fi
  curl -LsSf https://astral.sh/uv/install.sh | sh
  export PATH="$HOME/.local/bin:$PATH"
  log "uv installed."
}

install_node() {
  if need_cmd node; then
    log "Node already installed."
    return 0
  fi

  # fnm is the lightest way to get node without mise/nvm
  if ! need_cmd fnm; then
    curl -fsSL https://fnm.vercel.app/install.sh | bash -s -- --skip-shell
    export PATH="$HOME/.local/share/fnm:$PATH"
    eval "$(fnm env)"
  fi

  fnm install 22
  fnm default 22
  eval "$(fnm env)"
  log "Node $(node --version) installed via fnm."
}

install_neovim() {
  if need_cmd nvim; then
    log "Neovim already installed."
    return 0
  fi

  local arch
  arch="$(uname -m)"
  local suffix
  case "$arch" in
    x86_64)  suffix="x86_64" ;;
    aarch64) suffix="aarch64" ;;
    *) log "Skipping neovim (unsupported arch: $arch)."; return 0 ;;
  esac

  local url="https://github.com/neovim/neovim/releases/download/nightly/nvim-linux-${suffix}.appimage"
  mkdir -p "$HOME/.local/bin"
  curl -fsSL -o "$HOME/.local/bin/nvim" "$url"
  chmod +x "$HOME/.local/bin/nvim"

  # AppImage needs FUSE; extract if unavailable
  if ! "$HOME/.local/bin/nvim" --version &>/dev/null; then
    local tmp_dir
    tmp_dir="$(mktemp -d)"
    cd "$tmp_dir"
    "$HOME/.local/bin/nvim" --appimage-extract >/dev/null 2>&1
    mv squashfs-root/usr/bin/nvim "$HOME/.local/bin/nvim"
    rm -rf "$tmp_dir"
    cd -
  fi

  log "Neovim nightly installed."
}

install_gh_cli() {
  if need_cmd gh; then
    log "GitHub CLI already installed."
    return 0
  fi

  ensure_sudo
  sudo mkdir -p /usr/share/keyrings
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | sudo tee /usr/share/keyrings/githubcli-archive-keyring.gpg >/dev/null
  sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
  sudo apt-get update -y
  sudo apt-get install -y gh
  log "GitHub CLI installed."
}

install_pi() {
  if need_cmd pi; then
    log "pi already installed."
    return 0
  fi
  npm install -g @mariozechner/pi-coding-agent
  log "pi CLI installed."
}

main() {
  export DEBIAN_FRONTEND=noninteractive
  export PATH="$HOME/.local/bin:$PATH"

  apt_install
  install_uv
  install_node
  install_neovim
  install_gh_cli
  install_pi

  log ""
  log "Done. Installed: git, curl, tmux, ripgrep, jq, direnv, uv, node, neovim, gh, pi"
}

main "$@"

