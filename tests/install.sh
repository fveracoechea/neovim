#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
test_home=$(mktemp -d "${TMPDIR:-/tmp}/neovim-install.XXXXXX")
trap 'rm -rf "$test_home"' EXIT
export HOME="$test_home"
export XDG_CONFIG_HOME="$HOME/config with spaces"
target="$XDG_CONFIG_HOME/nvim"

bash "$repo/scripts/install.sh"
test -d "$target"
test ! -L "$target"
test -L "$target/init.lua"
test -f "$target/lsp/nixd.lua"
test -f "$target/lsp/relay_lsp.lua"
test ! -L "$target/nvim-pack-lock.json"
cmp "$repo/nvim/nvim-pack-lock.json" "$target/nvim-pack-lock.json"
bash "$repo/scripts/install.sh"

printf 'session data\n' >"$target/session.vim"
bash "$repo/scripts/install.sh"
test "$(cat "$target/session.vim")" = 'session data'

rm "$target/init.lua"
printf 'unrelated configuration\n' >"$target/init.lua"
if bash "$repo/scripts/install.sh" >"$HOME/conflict.log" 2>&1; then
  printf 'Installer accepted an unrelated configuration file\n' >&2
  exit 1
fi
test "$(cat "$target/init.lua")" = 'unrelated configuration'
rm "$target/init.lua"
bash "$repo/scripts/install.sh"

printf 'local plugin changes\n' >"$target/nvim-pack-lock.json"
if bash "$repo/scripts/install.sh" >"$HOME/lock-conflict.log" 2>&1; then
  printf 'Installer accepted an edited plugin lockfile\n' >&2
  exit 1
fi
test "$(cat "$target/nvim-pack-lock.json")" = 'local plugin changes'
rm "$target/nvim-pack-lock.json"
bash "$repo/scripts/install.sh" --development
test -L "$target/nvim-pack-lock.json"
test "$(readlink "$target/nvim-pack-lock.json")" = "$repo/nvim/nvim-pack-lock.json"
bash "$repo/scripts/install.sh" --development
cmp "$repo/nvim/nvim-pack-lock.json" "$target/nvim-pack-lock.json"

checkout="$HOME/checkout"
mkdir -p "$checkout"
cp -R "$repo/nvim" "$repo/scripts" "$checkout/"
chmod -R u+w "$checkout"
export XDG_CONFIG_HOME="$HOME/upgrades"
bash "$checkout/scripts/install.sh"
printf '\n' >>"$checkout/nvim/nvim-pack-lock.json"
bash "$checkout/scripts/install.sh"
cmp "$checkout/nvim/nvim-pack-lock.json" "$XDG_CONFIG_HOME/nvim/nvim-pack-lock.json"

export XDG_CONFIG_HOME="$HOME/directory-conflict"
mkdir -p "$XDG_CONFIG_HOME"
ln -s "$HOME/upgrades/nvim" "$XDG_CONFIG_HOME/nvim"
if bash "$checkout/scripts/install.sh" >"$HOME/directory-conflict.log" 2>&1; then
  printf 'Installer accepted a configuration directory link\n' >&2
  exit 1
fi
test -L "$XDG_CONFIG_HOME/nvim"

printf 'Neovim installation checks passed\n'
