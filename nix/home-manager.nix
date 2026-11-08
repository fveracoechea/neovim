{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.programs.neovim-config;
  installLock = pkgs.writeShellApplication {
    name = "install-neovim-lock";
    runtimeInputs = [pkgs.coreutils];
    text = builtins.readFile ../scripts/install-lock.sh;
  };
in {
  options.programs.neovim-config = {
    enable = lib.mkEnableOption "fveracoechea's shared Neovim configuration";
    pluginLockPath = lib.mkOption {
      type = lib.types.nullOr (lib.types.strMatching "/.*");
      default = null;
      description = "Development-only absolute path to the shared checkout's writable plugin lockfile.";
    };
  };

  config = lib.mkIf cfg.enable {
    xdg.configFile = {
      "nvim/init.lua".source = ../nvim/init.lua;
      "nvim/lua" = {
        source = ../nvim/lua;
        recursive = true;
      };
      "nvim/lsp" = {
        source = ../nvim/lsp;
        recursive = true;
      };
      "nvim/snippets" = {
        source = ../nvim/snippets;
        recursive = true;
      };
      "nvim/nvim-pack-lock.json" = lib.mkIf (cfg.pluginLockPath != null) {
        source = config.lib.file.mkOutOfStoreSymlink cfg.pluginLockPath;
      };
    };

    home.activation.neovimPluginLock = lib.mkIf (cfg.pluginLockPath == null) (
      lib.hm.dag.entryAfter ["linkGeneration"] ''
        run ${lib.getExe installLock} ${../nvim/nvim-pack-lock.json} ${lib.escapeShellArg "${config.xdg.configHome}/nvim/nvim-pack-lock.json"}
      ''
    );

    programs.neovim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;
      vimdiffAlias = true;
      withRuby = false;
      withPython3 = false;
      withNodeJs = false;
      withPerl = false;
      extraWrapperArgs = ["--prefix" "PATH" ":" (lib.makeBinPath config.programs.neovim.extraPackages)];
      extraPackages = with pkgs;
        [
          alejandra
          biome
          black
          curl
          fd
          fzf
          gcc
          gh
          git
          gnutar
          gzip
          graphql-language-service-cli
          imagemagick
          isort
          lazygit
          lua-language-server
          nixd
          oxfmt
          oxlint
          prettier
          ripgrep
          stylua
          tailwindcss-language-server
          tree-sitter
          typescript
          unzip
          vscode-langservers-extracted
          (callPackage ./stylelint-language-server.nix {})
        ]
        ++ lib.optionals stdenv.hostPlatform.isLinux [wl-clipboard xclip];
    };
  };
}
