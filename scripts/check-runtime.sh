#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
sandbox=$(mktemp -d "${TMPDIR:-/tmp}/neovim-runtime.XXXXXX")
export HOME="$sandbox/home"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_CACHE_HOME="$HOME/.cache"

bash "$repo/scripts/install.sh"
if ! bash "$repo/tests/start.sh" >"$sandbox/startup.log" 2>&1; then
  cat "$sandbox/startup.log" >&2
  printf 'Runtime test artifacts: %s\n' "$sandbox" >&2
  exit 1
fi
cat "$sandbox/startup.log"
cmp "$repo/nvim/nvim-pack-lock.json" "$XDG_CONFIG_HOME/nvim/nvim-pack-lock.json"
printf 'Runtime test artifacts: %s\n' "$sandbox"
