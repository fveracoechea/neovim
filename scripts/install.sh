#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
target="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
development=false
if [[ ${1:-} == --development && $# == 1 ]]; then
  development=true
elif [[ $# != 0 ]]; then
  printf 'Usage: bash scripts/install.sh [--development]\n' >&2
  exit 1
fi

while IFS= read -r -d '' source; do
  directory="$target${source#"$repo/nvim"}"
  if [[ -L $directory || (-e $directory && ! -d $directory) ]]; then
    printf 'Refusing to replace configuration directory: %s\n' "$directory" >&2
    exit 1
  fi
done < <(find "$repo/nvim" -type d -print0)

while IFS= read -r -d '' source; do
  file="$target/${source#"$repo/nvim/"}"
  if [[ -L $file && $(readlink "$file") == "$source" ]]; then
    continue
  fi
  if [[ -e $file || -L $file ]]; then
    printf 'Refusing to replace configuration file: %s\n' "$file" >&2
    exit 1
  fi
done < <(find "$repo/nvim" -type f ! -name nvim-pack-lock.json -print0)

lock="$target/nvim-pack-lock.json"
if $development; then
  mkdir -p "$target"
  if [[ -L $lock && $(readlink "$lock") == "$repo/nvim/nvim-pack-lock.json" ]]; then
    :
  elif [[ ! -e $lock && ! -L $lock ]] || { [[ -f $lock && ! -L $lock ]] && cmp -s "$repo/nvim/nvim-pack-lock.json" "$lock"; }; then
    rm -f "$lock"
    ln -s "$repo/nvim/nvim-pack-lock.json" "$lock"
  else
    printf 'Refusing to replace plugin lockfile: %s\n' "$lock" >&2
    exit 1
  fi
else
  bash "$repo/scripts/install-lock.sh" "$repo/nvim/nvim-pack-lock.json" "$lock"
fi

while IFS= read -r -d '' source; do
  file="$target/${source#"$repo/nvim/"}"
  mkdir -p "$(dirname "$file")"
  if [[ ! -L $file ]]; then
    ln -s "$source" "$file"
  fi
done < <(find "$repo/nvim" -type f ! -name nvim-pack-lock.json -print0)

printf 'Installed Neovim configuration in %s\n' "$target"
