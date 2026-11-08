#!/usr/bin/env bash
set -euo pipefail

export NEOVIM_TEST_ROOT
NEOVIM_TEST_ROOT=$(cd "$(dirname "$0")/.." && pwd)
"${NVIM_BIN:-nvim}" --headless \
  --cmd 'lua dofile(vim.env.NEOVIM_TEST_ROOT .. "/tests/capture-errors.lua")' \
  -c 'lua dofile(vim.env.NEOVIM_TEST_ROOT .. "/tests/smoke.lua")'
