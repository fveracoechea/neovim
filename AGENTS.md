# Agent instructions

- Run `just check` for installer tests and Lua/shell linting. Use `nix develop` if tools are missing.
- Run `just check-runtime` for runtime changes and `nix flake check` for Nix/Home Manager changes. Fix failures before finishing.
- Commit all changes and push them to `main`.
