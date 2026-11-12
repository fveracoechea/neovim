# Neovim

Shared Neovim configuration for Linux and macOS, with Home Manager and native installation options.
The configuration focuses on JavaScript, TypeScript, React, and web development, with Lua and Nix tooling.

- Neovim's built-in `vim.pack` manages plugins, with revisions pinned in [`nvim/nvim-pack-lock.json`](nvim/nvim-pack-lock.json).
- Catppuccin Mocha uses a transparent background, with Bufferline tabs and a Lualine statusline.
- Snacks supplies file search, an explorer, GitHub pickers, notifications, and Git tools.
- Mini supplies completion, snippets, sessions, commenting, pairs, and surround editing.
- Language servers provide diagnostics and navigation; Conform formats files on save.

## Contents

- [Installation](#installation)
- [Supported languages](#supported-languages)
- [Plugins](#plugins)
- [External packages](#external-packages)
- [Keybindings](#keybindings)
- [Configuration layout](#configuration-layout)
- [Updates and state](#updates-and-state)
- [Troubleshooting](#troubleshooting)
- [Checks](#checks)

## Installation

### Requirements

- **Neovim 0.12 or newer.** The TypeScript server also requires a TypeScript version that provides `tsc --lsp`.
- Internet access on first launch to download plugins and Treesitter parsers.
- A C compiler and the `tree-sitter` CLI to compile parsers.
- The [external packages](#external-packages) for the features you use.
- A Nerd Font is recommended for file, diagnostic, and statusline icons.

The Home Manager module supplies Neovim and external packages.
For a native installation, install these dependencies separately.

### Home Manager

Add this flake to your dotfiles flake and follow its existing inputs:

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

### Without Nix

From a checkout at your chosen revision, run:

```sh
bash scripts/install.sh
nvim --headless +qa
```

Open `nvim` after the initial downloads and parser builds finish.
`just install` is an alias for the installer when `just` is available.

The installer uses `$XDG_CONFIG_HOME/nvim`, or `~/.config/nvim` when the variable is unset.
It creates individual file links, not a directory link.
It refuses unrelated files, directory links, and plugin lockfiles with local changes.
Run it again after changing the checkout revision.
Keep this checkout: the configuration links point into it.

`fveracoechea/macos-dotfiles` pins a checkout and invokes this installer through `just neovim`.
Its Brewfile and Bun recipe supply the external tools.
No Nix or custom Lua loader is required.

## Supported languages

Support varies by language.
A Treesitter parser adds highlighting and indentation, not completion, diagnostics, or a language server.

| Language or file type | Language-server features | Formatting |
| --- | --- | --- |
| JavaScript, TypeScript, JSX, TSX | TypeScript (`tsc`), ESLint, Oxlint; GraphQL and Relay in configured projects | Prettier or Oxfmt |
| HTML | HTML server; Tailwind CSS and configured web linters | Prettier or Oxfmt |
| CSS, SCSS, Less | CSS server; Tailwind CSS, with Stylelint where configured | CSS uses the shared formatter chain; SCSS/Less use Oxfmt or LSP fallback |
| JSON, JSONC | JSON server with schemas for common configuration files | Prettier or Oxfmt |
| GraphQL | GraphQL server in configured projects | Prettier or Oxfmt |
| Lua | Lua language server with Neovim runtime awareness | StyLua |
| Nix | `nixd`, when installed | nixfmt, when installed |
| Python | No Python language server configured | No dedicated formatter configured |
| Markdown, MDX, YAML | No dedicated language server; MDX is treated as Markdown | Prettier or Oxfmt, subject to tool support |
| Astro, Vue, Svelte | Shared linting and Tailwind features where supported; no dedicated framework server | Prettier or Oxfmt, subject to tool support |
| Liquid | Tailwind class support where applicable; no dedicated language server | Prettier |

ESLint, Stylelint, Oxfmt, and Oxlint use project configuration to determine whether to start.
Install the project's dependencies and keep its lint configuration in the workspace.
Relay starts only in a Relay workspace and prefers `node_modules/.bin/relay-compiler`.
Tailwind includes class detection for helpers such as `cn`, `cva`, `cx`, and `tv`.

### Formatting behavior

Conform formats on save with a 1,200 ms timeout and an LSP fallback.
The shared formatter chain tries Prettier, then Oxfmt, stopping at the first available formatter.
Prettier requires a detected project configuration directory.
The chain does not mean each tool supports every listed language; framework support can require project-local Prettier plugins.
File types without an explicit formatter use Oxfmt when available.

### Treesitter parsers

These parsers install automatically on first launch:

| Group | Parsers |
| --- | --- |
| Web | `astro`, `css`, `graphql`, `html`, `javascript`, `jsdoc`, `liquid`, `scss`, `svelte`, `tsx`, `typescript`, `vue` |
| Programming and shell | `bash`, `lua`, `luadoc`, `luap`, `nix`, `python`, `vim`, `vimdoc` |
| Data and markup | `json`, `json5`, `markdown`, `markdown_inline`, `sql`, `toml`, `xml`, `yaml` |
| Build and configuration | `dockerfile`, `editorconfig`, `http`, `just`, `make`, `nginx`, `ssh_config` |
| Git | `diff`, `git_config`, `git_rebase`, `gitattributes`, `gitcommit`, `gitignore` |
| Embedded syntax | `comment`, `printf`, `query`, `regex` |

## Plugins

The plugin catalog lives in [`nvim/init.lua`](nvim/init.lua).
Settings live in [`nvim/lua/plugins/`](nvim/lua/plugins).

| Plugin | Purpose |
| --- | --- |
| [catppuccin/nvim](https://github.com/catppuccin/nvim) | Mocha theme with transparent backgrounds |
| [nvim-mini/mini.nvim](https://github.com/nvim-mini/mini.nvim) | Completion, snippets, sessions, pairs, surround, comments, diffs, icons, and keybinding hints |
| [folke/snacks.nvim](https://github.com/folke/snacks.nvim) | Dashboard, pickers, right-side explorer, Git/GitHub tools, images, notifications, scratch buffers, and zen mode |
| [nvim-treesitter/nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) | Parser installation, highlighting, and indentation |
| [JoosepAlviste/nvim-ts-context-commentstring](https://github.com/JoosepAlviste/nvim-ts-context-commentstring) | Context-aware comment syntax for mixed-language files |
| [windwp/nvim-ts-autotag](https://github.com/windwp/nvim-ts-autotag) | Automatic tag closing and renaming |
| [neovim/nvim-lspconfig](https://github.com/neovim/nvim-lspconfig) | Language-server defaults and utilities |
| [antosha417/nvim-lsp-file-operations](https://github.com/antosha417/nvim-lsp-file-operations) | Bundled LSP file-operation plugin; no explicit setup in this configuration |
| [stevearc/conform.nvim](https://github.com/stevearc/conform.nvim) | Formatting on save |
| [lewis6991/gitsigns.nvim](https://github.com/lewis6991/gitsigns.nvim) | Git change signs and current-line blame |
| [folke/todo-comments.nvim](https://github.com/folke/todo-comments.nvim) | Highlighting and search for TODO/FIXME comments |
| [akinsho/bufferline.nvim](https://github.com/akinsho/bufferline.nvim) | Numbered buffer tabs |
| [nvim-lualine/lualine.nvim](https://github.com/nvim-lualine/lualine.nvim) | Statusline with diagnostics, LSP status, and buffer count |
| [ChmaraX/herdr-nvim](https://github.com/ChmaraX/herdr-nvim) | Herdr integration under `<leader>h` |
| [nvim-lua/plenary.nvim](https://github.com/nvim-lua/plenary.nvim) | Lua utility dependency |
| [MunifTanjim/nui.nvim](https://github.com/MunifTanjim/nui.nvim) | UI component dependency |

## External packages

Home Manager installs the following packages from [`nix/home-manager.nix`](nix/home-manager.nix).
For native installs, use the command column to check your `PATH`; package names can differ between package managers.

| Purpose | Home Manager packages | Commands |
| --- | --- | --- |
| Downloads and builds | `gcc`, `tree-sitter`, `curl`, `git`, `gnutar`, `gzip`, `unzip` | `cc`, `tree-sitter`, `curl`, `git`, `tar`, `gzip`, `unzip` |
| Search | `fd`, `fzf`, `ripgrep` | `fd`, `fzf`, `rg` |
| Git and GitHub | `lazygit`, `gh` | `lazygit`, `gh` |
| Web language servers | `vscode-langservers-extracted` | `vscode-css-language-server`, `vscode-html-language-server`, `vscode-json-language-server`, `vscode-eslint-language-server` |
| TypeScript | `typescript` | `tsc` with `--lsp` support |
| Tailwind CSS | `tailwindcss-language-server` | `tailwindcss-language-server` |
| GraphQL | `graphql-language-service-cli` | `graphql-lsp` |
| Stylelint | `stylelint`, custom `stylelint-language-server` derivation | `stylelint`, `stylelint-language-server` |
| Web linting and formatting | `oxlint`, `oxfmt`, `prettier` | `oxlint`, `oxfmt`, `prettier` |
| Lua | `lua-language-server`, `stylua` | `lua-language-server`, `stylua` |
| Nix | `nixd`, `nixfmt` | `nixd`, `nixfmt` |
| Images | `imagemagick` | `magick` |
| Linux clipboard | `wl-clipboard`, `xclip` | `wl-copy`, `wl-paste`, `xclip` |

`nixd` and `nixfmt` are optional outside Nix.
Relay projects must supply `relay-compiler`; the module does not install it.
macOS clipboard integration uses `pbcopy` and `pbpaste`.
GitHub pickers need an authenticated `gh` session, and image display needs a compatible terminal.
No plugin requires Neovim's Python, Ruby, Node, or Perl remote-plugin host.
External language servers still need their own runtime dependencies.

## Keybindings

`<leader>` is **Space**.
Press Space and wait for Mini Clue to show available mappings.
LSP mappings appear only when an attached server supports the operation.

| Keys | Action |
| --- | --- |
| `Ctrl-s` or `Esc` in normal mode | Save the current file |
| `<leader>ff` / `<leader>fa` | Find files / include hidden and ignored files |
| `<leader>fr` | Find recent files |
| `<leader>fs` / `<leader>fw` | Search project text / word under the cursor |
| `<leader>fc` | Search open buffers |
| `Ctrl-n` / `Ctrl-y` | Open explorer at the working directory / current file |
| `Tab` / `Shift-Tab` in normal mode | Next / previous buffer |
| `<leader>1` through `<leader>9` | Jump to a numbered buffer |
| `<leader>xx` / `<leader>xo` | Close current / other buffers |
| `gd` / `K` | Go to definition / show hover information |
| `<leader>lr` / `<leader>li` / `<leader>lt` | Find references / implementations / type definitions |
| `<leader>ca` / `<leader>rn` | Code actions / rename symbol |
| `<leader>sD` | Search diagnostics across buffers |
| `<leader>Dp` / `<leader>Dn` | Previous / next diagnostic |
| `<leader>/` | Comment the current line or selection |
| `<leader>gb` / `<leader>gB` | Show line blame / open repository location in a browser |
| `<leader>gf` / `<leader>gl` | Lazygit file history / repository log |
| `<leader>gi` / `<leader>gp` | Search open GitHub issues / pull requests |
| `]h` / `[h` | Next / previous diff hunk |
| `<leader>ws` / `<leader>wr` / `<leader>wd` | Save / restore / delete the session named after the current directory |
| `<leader>st` | Search TODO comments |
| `<leader>.` / `<leader>S` | Toggle / select a scratch buffer |
| `<leader>z` / `<leader>Z` | Toggle zen mode / zoom |
| `Tab` / `Shift-Tab` in insert mode | Navigate completion items or snippet placeholders |

See [`nvim/lua/config/keymaps.lua`](nvim/lua/config/keymaps.lua) for the complete list.
Normal-mode `Esc` saves the file instead of clearing search highlights.

## Configuration layout

```text
flake.nix                 Home Manager module export, development shell, and checks
justfile                  Install, development, and check commands
nix/                      Home Manager module, Nix checks, and Stylelint packaging
nvim/init.lua             Plugin catalog and configuration entry point
nvim/nvim-pack-lock.json   Pinned plugin revisions
nvim/lua/config/          Editor options, mappings, autocommands, and enabled LSPs
nvim/lua/plugins/         Plugin settings, formatter selection, and parser list
nvim/lsp/                 Language-server overrides
nvim/snippets/            Custom snippets
scripts/                  Installers and isolated runtime check
tests/                    Installer tests and editor smoke tests
```

Add plugins in `nvim/init.lua` and configure them under `nvim/lua/plugins/`.
Enable language servers in `nvim/lua/config/lsp.lua` and place overrides in `nvim/lsp/`.
Change formatter selection in `nvim/lua/plugins/conform.lua` and parsers in `nvim/lua/plugins/treesitter.lua`.

## Updates and state

### Plugin updates

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

### Sessions and undo

Sessions and persistent undo live under Neovim's state directory, not in the shared checkout.
Existing sessions in `~/.config/nvim` remain untouched; copy any sessions you want into `stdpath("state")/sessions`.
Inspect the state directory with `:lua print(vim.fn.stdpath("state"))`.
Session names use the current directory's basename, so equally named directories share a session name.

## Troubleshooting

- **Installer refuses a file.** Back up or move conflicting configuration files, then rerun the installer.
  It does not overwrite unrelated files or replace a symlinked configuration directory.
- **Plugin lockfile conflict.** Preserve your local changes before upgrading.
  Consumer upgrades replace a lockfile only when it matches the last installed version.
- **Parser build fails.** Check `cc` and `tree-sitter` on `PATH`, plus network access.
  First-time headless startup waits for parser compilation.
- **Language server does not attach.** Use `:checkhealth vim.lsp` and inspect `:lua vim.print(vim.lsp.get_clients())`.
  Check its executable, project dependencies, and root configuration.
- **TypeScript server fails to start.** Check that your `tsc` supports `--lsp`; older compiler-only releases are insufficient.
- **Formatting does not run.** Use `:ConformInfo` to inspect the selected formatter and configuration.
- **Clipboard does not work.** Run `:checkhealth vim.provider` and check the platform clipboard tools.
- **Icons appear as boxes.** Select a Nerd Font in your terminal settings.

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
Its offline startup check uses pinned plugin sources and cached parser fixtures.
It also checks development lockfile links and the plain installer.
CI runs these checks on Linux and the native runtime check on macOS.

For Nix lint tools, use `nix develop`.
The development shell includes `just`, `stylua`, `luacheck`, `shellcheck`, `shfmt`, and `nixfmt`.
It does not supply the complete editor runtime toolchain.
For native lint checks, install `just`, `stylua`, `luacheck`, and `shellcheck`.
