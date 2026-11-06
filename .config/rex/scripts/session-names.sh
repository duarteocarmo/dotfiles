#!/bin/sh
set -eu

export PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:${PATH:-}"
unset REX_SERVER REX_SESSION REX_BLOCK REX_CLIENT
script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
exec rex --autostart=false do --all "$script_dir/session-names.lua"
