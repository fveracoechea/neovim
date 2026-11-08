set shell := ["bash", "-euo", "pipefail", "-c"]

default:
    @just --list

install:
    bash scripts/install.sh

develop:
    bash scripts/install.sh --development

check: check-install check-lua check-shell

check-install:
    bash tests/install.sh

check-lua:
    stylua --check nvim tests
    luacheck nvim tests

check-shell:
    shellcheck scripts/*.sh tests/*.sh

check-runtime:
    bash scripts/check-runtime.sh
