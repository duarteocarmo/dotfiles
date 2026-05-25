#!/usr/bin/env bash
set -euo pipefail

# Minimal Linux setup for coding with pi.
# Installs/upgrades only: nvim, gh, glab, tree, tmux, jq, direnv, unzip, curl, ca-certificates, git, uv, atuin, lazygit
# Also adds shell aliases for bash or zsh.
#   bash setup/linux-minimal.sh

APT_PACKAGES=(
  ca-certificates
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

  local package
  for package in "${APT_PACKAGES[@]}"; do
    if sudo apt-get install -y "$package"; then
      log "$package installed/upgraded."
    else
      log "Skipping $package (install failed)."
    fi
  done

  sudo apt-get clean
}

run_step() {
  local name="$1"
  shift

  if "$@"; then
    return 0
  fi

  log "Skipping $name (failed)."
}

install_uv() {
  curl -LsSf https://astral.sh/uv/install.sh | sh
  export PATH="$HOME/.local/bin:$PATH"
  log "uv installed/upgraded."
}

install_gh_cli() {
  ensure_sudo
  if ! grep -Rqs "https://cli.github.com/packages" /etc/apt/sources.list /etc/apt/sources.list.d; then
    sudo mkdir -p /usr/share/keyrings
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
      | sudo tee /usr/share/keyrings/githubcli-archive-keyring.gpg >/dev/null
    sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
      | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
  fi
  sudo apt-get update -y
  sudo apt-get install -y gh
  log "GitHub CLI installed/upgraded."
}

install_glab() {
  local arch
  arch="$(uname -m)"

  local release_json
  release_json="$(curl -fsSL https://gitlab.com/api/v4/projects/34675721/releases)"

  local glab_arch
  case "$arch" in
    x86_64) glab_arch="amd64" ;;
    aarch64) glab_arch="arm64" ;;
    *) glab_arch="$arch" ;;
  esac

  local url
  url="$(printf '%s' "$release_json" | jq -r --arg glab_arch "$glab_arch" '
    .[0].assets.links[]
    | select(.name | endswith(".tar.gz"))
    | select(.name | contains("linux_" + $glab_arch))
    | .direct_asset_url
  ' | head -n 1)"

  if [[ -z "$url" ]]; then
    log "Skipping glab (unsupported arch: $arch)."
    return 0
  fi

  local tmp_dir
  tmp_dir="$(mktemp -d)"
  if ! curl -fsSL -o "$tmp_dir/glab.tar.gz" "$url"; then
    rm -rf "$tmp_dir"
    log "Skipping glab (download failed)."
    return 0
  fi

  if ! tar -xz -C "$tmp_dir" -f "$tmp_dir/glab.tar.gz"; then
    rm -rf "$tmp_dir"
    log "Skipping glab (extract failed)."
    return 0
  fi

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
  local arch
  arch="$(uname -m)"

  local lazygit_arch
  case "$arch" in
    aarch64) lazygit_arch="arm64" ;;
    *) lazygit_arch="$arch" ;;
  esac

  local release_json
  if ! release_json="$(curl -fsSL https://api.github.com/repos/jesseduffield/lazygit/releases/latest)"; then
    log "Skipping lazygit (could not fetch latest version)."
    return 0
  fi

  local url
  url="$(printf '%s' "$release_json" | jq -r --arg lazygit_arch "$lazygit_arch" '
    .assets[]
    | select(.name | endswith(".tar.gz"))
    | select(.name | contains("linux_" + $lazygit_arch))
    | .browser_download_url
  ' | head -n 1)"

  if [[ -z "$url" ]]; then
    log "Skipping lazygit (unsupported arch: $arch)."
    return 0
  fi

  local tmp_dir
  tmp_dir="$(mktemp -d)"

  if ! curl -fsSL -o "$tmp_dir/lazygit.tar.gz" "$url"; then
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

  run_step "APT packages" apt_install_or_upgrade
  run_step "uv" install_uv
  run_step "GitHub CLI" install_gh_cli
  run_step "glab" install_glab
  run_step "Atuin" install_atuin
  run_step "lazygit" install_lazygit
  run_step "aliases" setup_aliases

  log "Done."
}

main "$@"
