#!/usr/bin/env bash
set -euo pipefail

# Minimal Linux setup for coding with pi.
# Installs/upgrades only: nvim, gh, glab, tree, tmux, jq, direnv, unzip, curl, git, uv, atuin, lazygit
# Also adds shell aliases for bash or zsh.
#   bash setup/linux-minimal.sh

APT_PACKAGES=(
  curl
  git
  tmux
  tree
  jq
  direnv
  unzip
  neovim
)

ALIASES=$(cat <<'ALIASES'
alias gst='git status'
alias gp='git push'
alias ga='git add'
alias gc='git commit'
alias vi='nvim'
ALIASES
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

apt_install_or_upgrade() {
  ensure_sudo
  sudo apt-get update -y
  sudo apt-get install -y "${APT_PACKAGES[@]}"
  sudo apt-get clean
  log "APT packages installed/upgraded."
}

install_uv() {
  curl -LsSf https://astral.sh/uv/install.sh | sh
  export PATH="$HOME/.local/bin:$PATH"
  log "uv installed/upgraded."
}

install_gh_cli() {
  ensure_sudo
  sudo mkdir -p /usr/share/keyrings
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | sudo tee /usr/share/keyrings/githubcli-archive-keyring.gpg >/dev/null
  sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
  sudo apt-get update -y
  sudo apt-get install -y gh
  log "GitHub CLI installed/upgraded."
}

install_glab() {
  local arch
  arch="$(uname -m)"
  local glab_arch
  case "$arch" in
    x86_64) glab_arch="x86_64" ;;
    aarch64) glab_arch="arm64" ;;
    *) log "Skipping glab (unsupported arch: $arch)."; return 0 ;;
  esac

  local version
  version="$(curl -fsSL https://gitlab.com/api/v4/projects/34675721/releases | jq -r '.[0].tag_name' | sed 's/^v//')"
  local url="https://gitlab.com/gitlab-org/cli/-/releases/v${version}/downloads/glab_${version}_linux_${glab_arch}.tar.gz"

  local tmp_dir
  tmp_dir="$(mktemp -d)"
  curl -fsSL "$url" | tar -xz -C "$tmp_dir"
  mkdir -p "$HOME/.local/bin"
  mv "$tmp_dir/bin/glab" "$HOME/.local/bin/glab"
  chmod +x "$HOME/.local/bin/glab"
  rm -rf "$tmp_dir"
  log "glab installed/upgraded."
}

install_atuin() {
  if apt-cache show atuin >/dev/null 2>&1; then
    ensure_sudo
    sudo apt-get install -y atuin
    log "Atuin installed/upgraded."
    return 0
  fi

  curl -fsSL https://setup.atuin.sh | sh
  export PATH="$HOME/.local/bin:$PATH"
  log "Atuin installed/upgraded."
}

install_lazygit() {
  if ! LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": *"v\K[^"]*'); then
    log "Skipping lazygit (could not fetch latest version)."
    return 0
  fi

  LAZYGIT_ARCH=$(uname -m | sed -e 's/aarch64/arm64/')
  local tmp_dir
  tmp_dir="$(mktemp -d)"

  if ! curl -Lo "$tmp_dir/lazygit.tar.gz" "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_${LAZYGIT_ARCH}.tar.gz"; then
    rm -rf "$tmp_dir"
    log "Skipping lazygit (download failed)."
    return 0
  fi

  if ! tar xf "$tmp_dir/lazygit.tar.gz" -C "$tmp_dir" lazygit; then
    rm -rf "$tmp_dir"
    log "Skipping lazygit (extract failed)."
    return 0
  fi

  ensure_sudo
  if ! sudo install "$tmp_dir/lazygit" -D -t /usr/local/bin/; then
    rm -rf "$tmp_dir"
    log "Skipping lazygit (install failed)."
    return 0
  fi

  rm -rf "$tmp_dir"
  log "lazygit installed/upgraded."
}

detect_shell_config() {
  local shell_name
  shell_name="$(basename "${SHELL:-}")"

  case "$shell_name" in
    bash) printf '%s\n' "$HOME/.bashrc" ;;
    zsh) printf '%s\n' "$HOME/.zshrc" ;;
    *) log "Skipping aliases (unsupported shell: ${SHELL:-unknown})."; return 1 ;;
  esac
}

setup_aliases() {
  local shell_config
  shell_config="$(detect_shell_config)" || return 0
  touch "$shell_config"

  if grep -qF "alias gst='git status'" "$shell_config"; then
    log "Aliases already configured."
    return 0
  fi

  {
    printf '\n# Minimal setup aliases\n'
    printf '%s\n' "$ALIASES"
  } >>"$shell_config"

  log "Aliases added to $shell_config."
}

main() {
  export DEBIAN_FRONTEND=noninteractive
  export PATH="$HOME/.local/bin:$PATH"

  apt_install_or_upgrade
  install_uv
  install_gh_cli
  install_glab
  install_atuin
  install_lazygit
  setup_aliases

  log "Done."
}

main "$@"
