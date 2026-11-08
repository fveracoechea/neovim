# Neovim

One Lua configuration for Linux and macOS.
Neovim 0.12 or newer loads plugins through `vim.pack`.
`nvim/nvim-pack-lock.json` pins the plugin revisions for both installation adapters.
The first launch downloads plugins, the CodeSnap native library, and Treesitter parsers.
Parser compilation needs a C compiler and `tree-sitter`.

## Home Manager

Add this flake to the consumer and follow its Home package set:

```nix
inputs.neovim.url = "github:fveracoechea/neovim";
inputs.neovim.inputs.nixpkgs.follows = "nixpkgs";
inputs.neovim.inputs.home-manager.follows = "home-manager";
```

```nix
imports = [inputs.neovim.homeManagerModules.default];
programs.neovim-config.enable = true;
```

The module supplies Neovim, external tools, and store-backed configuration files.
It leaves the config directory writable and installs the plugin lockfile as a writable copy.
Consumer upgrades replace that copy only when it still matches the previously installed lockfile.
Local changes cause an error instead of being overwritten.
Checks currently target `x86_64-linux`; the macOS installation does not use Nix.

## Without Nix

Clone the repo, check out the commit chosen by your dotfiles, then run:

```sh
bash scripts/install.sh
nvim --headless +qa
```

The installer uses `$XDG_CONFIG_HOME/nvim`, or `~/.config/nvim` when the variable is unset.
It creates individual file links, not a directory link.
It refuses unrelated files, directory links, and plugin lockfiles with local changes.
Run it again after changing the checkout revision.
Keep this checkout: the configuration links point into it.

`fveracoechea/macos-dotfiles` pins a checkout and invokes this installer through `just neovim`.
Its Brewfile and Bun recipe supply the external tools.
No Nix or custom Lua loader is required.

### External tools

The native installation expects these commands on `PATH`:

```text
cc tree-sitter curl tar git fd fzf rg gh lazygit unzip
graphql-lsp stylelint-language-server biome lua-language-server
oxfmt oxlint tsc stylua prettier isort black magick
vscode-css-language-server vscode-html-language-server
vscode-json-language-server vscode-eslint-language-server
tailwindcss-language-server
```

`nixd` and `alejandra` are optional outside Nix.
Relay starts only in a Relay workspace and prefers its project-local `node_modules/.bin/relay-compiler`.
Clipboard integration uses the platform's provider: `pbcopy` on macOS, Wayland/X11 tools on Linux.

## Plugin updates

Make plugin changes in this repository, not in a pinned consumer checkout.
From a writable development checkout:

```sh
bash scripts/install.sh --development
nvim
```

Run `:lua vim.pack.update()`, review the lockfile diff, and run the checks before committing.
Advance the consumer's flake input or Git revision only after that commit passes.
The development installer links the lockfile into the checkout; it does not bypass conflict checks.
Home Manager has the equivalent development-only `programs.neovim-config.pluginLockPath` option.
Keep the Lua configuration and lockfile at the same revision when using that option.

Sessions and persistent undo live under Neovim's state directory, not in the shared checkout.
Existing sessions in `~/.config/nvim` remain untouched; copy any sessions you want into `stdpath("state")/sessions`.

## Checks

```sh
just check
just check-runtime
nix flake check
```

`just check` covers installer behavior and Lua/shell linting.
`just check-runtime` installs into an isolated home and starts the real editor with real plugin downloads and parser compilation.
It checks plugin revisions, tools, mappings, state paths, parsers, and language-server initialization.
Test artifacts stay in the printed temporary directory.

`nix flake check` stages the Home Manager-generated home files and runs its lockfile activation before startup.
Its offline startup check uses pinned plugin sources and cached parser/native-library fixtures.
It also checks development lockfile links and the plain installer.
CI runs these checks on Linux and the native runtime check on macOS.

For Nix lint tools, use `nix develop`.
Native tools are `just`, `stylua`, `luacheck`, and `shellcheck`.
