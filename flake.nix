{
  description = "Shared Neovim configuration for Nix and native installations";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs: let
    system = "x86_64-linux";
    pkgs = import inputs.nixpkgs {inherit system;};
  in {
    homeManagerModules.default = import ./nix/home-manager.nix;
    checks.${system} = import ./nix/checks.nix {inherit inputs pkgs;};
    devShells.${system}.default = pkgs.mkShell {
      packages = with pkgs; [alejandra just stylua luaPackages.luacheck shellcheck shfmt];
    };
  };
}
