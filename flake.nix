{
  description = "dz0ny's nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-25.11-darwin";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin/nix-darwin-25.11";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Shared Claude Code configuration for Niteo
    niteo-claude.url = "git+ssh://git@github.com/teamniteo/claude";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      nixpkgs-unstable,
      nix-darwin,
      home-manager,
      niteo-claude,
    }:
    let
      system = "aarch64-darwin";

      pkgs-unstable = import nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };

      homeconfig =
        { pkgs, lib, ... }:
        {
          home.username = "dz0ny";
          home.homeDirectory = lib.mkForce "/Users/dz0ny";
          home.stateVersion = "25.11";

          programs.home-manager.enable = true;

          # Claude Code (ONLY teamniteo/claude rules, no local overrides/merges)
          programs.claude-code = {
            enable = true;
            package = pkgs-unstable.claude-code;

            mcpServers = niteo-claude.lib.mcpServers pkgs;

            settings = {
              enabledPlugins = niteo-claude.lib.enabledPlugins;
              permissions.allow = niteo-claude.lib.permissions.allow;
            };
          };
        };

      configuration =
        { pkgs, ... }:
        {
          # Minimal nix-darwin host config (required shell for HM on darwin)
          nixpkgs.hostPlatform = system;
        };
    in
    {
      darwinConfigurations."dz0ny" = nix-darwin.lib.darwinSystem {
        modules = [
          configuration
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;

            home-manager.users.dz0ny = homeconfig;

            home-manager.extraSpecialArgs = {
              inherit niteo-claude;
            };
          }
        ];
      };

      darwinPackages = self.darwinConfigurations."dz0ny".pkgs;
      homeconfig = homeconfig;
    };
}
