#!/usr/bin/env bash
set -euo pipefail

seed=$1
target=$2
baseline="$target.base"

for file in "$target" "$baseline"; do
  if [[ -L $file || (-e $file && ! -f $file) ]]; then
    printf 'Refusing to replace plugin lock path: %s\n' "$file" >&2
    exit 1
  fi
done

if [[ -f $target ]] && ! cmp -s "$seed" "$target"; then
  if [[ ! -f $baseline ]] || ! cmp -s "$baseline" "$target"; then
    printf 'Plugin lockfile has local changes: %s\nUpdate plugins in the shared Neovim checkout instead.\n' "$target" >&2
    exit 1
  fi
fi

mkdir -p "$(dirname "$target")"
install -m644 "$seed" "$target"
install -m644 "$seed" "$baseline"
