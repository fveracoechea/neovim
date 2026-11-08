{
  inputs,
  pkgs,
}: let
  inherit (pkgs) lib;
  source = ../.;
  home = inputs.home-manager.lib.homeManagerConfiguration {
    inherit pkgs;
    modules = [
      ./home-manager.nix
      {
        home.username = "neovim-test";
        home.homeDirectory = "/tmp/neovim-test";
        home.stateVersion = "25.05";
        programs.neovim-config.enable = true;
      }
    ];
  };
  development = inputs.home-manager.lib.homeManagerConfiguration {
    inherit pkgs;
    modules = [
      ./home-manager.nix
      {
        home.username = "neovim-development";
        home.homeDirectory = "/tmp/neovim-development";
        home.stateVersion = "25.05";
        programs.neovim-config = {
          enable = true;
          pluginLockPath = "/tmp/neovim-checkout/nvim-pack-lock.json";
        };
      }
    ];
  };
  configDir = ../nvim;
  lock = lib.importJSON (configDir + "/nvim-pack-lock.json");
  pluginSources = lib.mapAttrs (_: plugin:
    builtins.fetchGit {
      url = plugin.src;
      inherit (plugin) rev;
    })
  lock.plugins;
  languages = lib.pipe (lib.fileContents (configDir + "/lua/plugins/treesitter.lua")) [
    (lib.splitString "\n")
    (map (builtins.match ''[ ]+"([a-z_0-9]+)",''))
    (builtins.filter (match: match != null))
    (map builtins.head)
  ];
  parserFixtures = builtins.filter (grammar: builtins.elem grammar.language languages) pkgs.vimPlugins.nvim-treesitter.allGrammars;
  codesnapVersion = (builtins.fromTOML (lib.fileContents (pluginSources."codesnap.nvim" + "/project.toml"))).project.version;
  codesnapLibrary = pkgs.fetchurl {
    url = "https://github.com/mistricky/codesnap.nvim/releases/download/v${codesnapVersion}/linux-x86_64_generator.so";
    hash = "sha256-B8w5JBG9rWfsW+m1DXEzwhsXo7m8TWae9SJJq2X29Qg=";
  };
in {
  neovim-installation = pkgs.runCommand "neovim-installation" {nativeBuildInputs = [pkgs.bash];} ''
    bash ${source}/tests/install.sh

    export HOME=/tmp/neovim-test
    mkdir -p "$HOME"
    cp -R ${home.config.home-files}/. "$HOME/"
    chmod -R u+w "$HOME"
    run() { "$@"; }
    ${home.config.home.activation.neovimPluginLock.data}
    test -L "$HOME/.config/nvim/init.lua"
    test ! -L "$HOME/.config/nvim"
    cmp ${configDir}/nvim-pack-lock.json "$HOME/.config/nvim/nvim-pack-lock.json"
    ${home.config.home.activation.neovimPluginLock.data}

    mkdir -p /tmp/neovim-development /tmp/neovim-checkout
    install -m644 ${configDir}/nvim-pack-lock.json /tmp/neovim-checkout/nvim-pack-lock.json
    cp -R ${development.config.home-files}/. /tmp/neovim-development/
    test -L /tmp/neovim-development/.config/nvim/nvim-pack-lock.json
    cmp /tmp/neovim-checkout/nvim-pack-lock.json /tmp/neovim-development/.config/nvim/nvim-pack-lock.json
    printf 'writable development lock\n' > /tmp/neovim-development/.config/nvim/nvim-pack-lock.json
    test "$(cat /tmp/neovim-checkout/nvim-pack-lock.json)" = 'writable development lock'
    test -L /tmp/neovim-development/.config/nvim/nvim-pack-lock.json
    touch "$out"
  '';

  neovim-smoke-test =
    pkgs.runCommand "neovim-smoke-test" {
      nativeBuildInputs = [home.config.programs.neovim.finalPackage pkgs.bash];
    } ''
      set -euo pipefail
      export HOME=/tmp/neovim-test
      export XDG_CONFIG_HOME=$HOME/.config
      export XDG_DATA_HOME=$HOME/.local/share
      export XDG_STATE_HOME=$HOME/.local/state
      export XDG_CACHE_HOME=$HOME/.cache
      export NEOVIM_NIX_TEST=1
      export NEOVIM_OFFLINE_TEST=1
      mkdir -p "$HOME" "$XDG_DATA_HOME/nvim/site/pack/core/opt" "$XDG_DATA_HOME/nvim/site/parser"
      cp -R ${home.config.home-files}/. "$HOME/"
      chmod -R u+w "$HOME"
      run() { "$@"; }
      ${home.config.home.activation.neovimPluginLock.data}

      ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: source: ''
          cp -R ${source} "$XDG_DATA_HOME/nvim/site/pack/core/opt/${name}"
        '')
        pluginSources)}
      chmod -R u+w "$XDG_DATA_HOME"
      mkdir -p "$XDG_DATA_HOME/nvim/site/pack/core/opt/codesnap.nvim/lua/libs"
      cp ${codesnapLibrary} "$XDG_DATA_HOME/nvim/site/pack/core/opt/codesnap.nvim/lua/libs/linux-x86_64_generator.so"
      echo '${codesnapVersion}' > "$XDG_DATA_HOME/nvim/site/pack/core/opt/codesnap.nvim/lua/libs/.version"

      ${lib.concatMapStringsSep "\n" (grammar: ''
          cp ${grammar}/parser "$XDG_DATA_HOME/nvim/site/parser/${grammar.language}.so"
        '')
        parserFixtures}
      cp -R ${pluginSources.nvim-treesitter}/runtime/queries "$XDG_DATA_HOME/nvim/site/queries"

      NVIM_BIN=${home.config.programs.neovim.finalPackage}/bin/nvim bash ${source}/tests/start.sh > startup.log 2>&1 || { cat startup.log; exit 1; }
      cat startup.log
      cmp ${configDir}/nvim-pack-lock.json "$XDG_CONFIG_HOME/nvim/nvim-pack-lock.json"
      touch "$out"
    '';

  neovim-lua-lint =
    pkgs.runCommand "neovim-lua-lint" {
      nativeBuildInputs = [pkgs.stylua pkgs.luaPackages.luacheck pkgs.shellcheck pkgs.alejandra];
    } ''
      export HOME=$TMPDIR
      stylua --config-path ${../.stylua.toml} --check ${configDir} ${../tests}
      luacheck --config ${../.luacheckrc} --no-cache ${configDir} ${../tests}
      shellcheck ${../scripts}/*.sh ${../tests}/*.sh
      alejandra --check ${../flake.nix} ${./.}
      touch "$out"
    '';
}
