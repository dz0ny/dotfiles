{
  # Result of `nix flake init -t nix-darwin/master` command as documented in nix-darwin setup.
  description = "Example nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # ============================================================================
    # home-manager (OPTIONAL - currently commented out)
    # ============================================================================
    # home-manager manages user-level configuration files (dotfiles) declaratively.
    # It's useful for managing configs like .zshrc, .gitconfig, vim settings, etc.
    #
    # To enable home-manager:
    # 1. Uncomment the lines below
    # 2. Add home-manager.darwinModules.home-manager to the modules list
    # 3. Configure it in a separate home.nix or within your configuration
    #
    # See: https://nix-community.github.io/home-manager/
    #
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      nix-darwin,
      nixpkgs,
      sops-nix,
      home-manager,
    }:
    let
      configuration =
        { pkgs, ... }:
        {
          networking.hostName = "Janezs-Mac-mini";

          # List packages installed in system profile. To search by name, run:
          # $ nix-env -qaP | grep wget
          environment.systemPackages = [
            pkgs.vim
          ];

          # Necessary for using flakes on this system.
          nix.settings.experimental-features = "nix-command flakes";

          # Enable alternative shell support in nix-darwin.
          # programs.fish.enable = true;

          # Set Git commit hash for darwin-version.
          system.configurationRevision = self.rev or self.dirtyRev or null;

          # Used for backwards compatibility, please read the changelog before changing.
          # $ darwin-rebuild changelog
          system.stateVersion = 6;

          # The platform the configuration will be used on.
          # This will be automatically detected during bootstrap
          nixpkgs.hostPlatform = "aarch64-darwin";

          # Required for Determinate:
          nix.enable = false; # Disable nix-darwin’s Nix management

          # Primary user (required by nix-darwin for homebrew, system.defaults, etc.)
          system.primaryUser = "dz0ny";

          # Enable Homebrew management through nix-darwin
          homebrew.enable = true;

          # Never uninstall Homebrew packages that aren't declared here. We only
          # want nix-darwin to *ensure* the packages in .nixmac/homebrew/data.json
          # are installed — apps installed manually via `brew` stay untouched.
          # ("uninstall"/"zap" would remove anything not listed; "none" leaves
          # existing installs alone.)
          homebrew.onActivation.cleanup = "none";

          # Keep Homebrew-managed apps current when this configuration activates
          # (Pareto Security "update managed apps" posture): refresh formulae and
          # upgrade outdated casks/brews on every `darwin-rebuild switch`.
          homebrew.onActivation.autoUpdate = true;
          homebrew.onActivation.upgrade = true;

          # Enable if you want to allow unfree packages (e.g. some fonts, or certain applications). Leave false to avoid them entirely.
          # nixpkgs.config.allowUnfree = true;
        };
    in
    {
      # Nix code formatter (run with `nix fmt`).
      formatter."aarch64-darwin" = nixpkgs.legacyPackages."aarch64-darwin".nixfmt-rfc-style;

      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#Janezs-Mac-mini
      darwinConfigurations."Janezs-Mac-mini" = nix-darwin.lib.darwinSystem {
        modules = [
          configuration
          ./.nixmac
          inputs.sops-nix.darwinModules.sops
          home-manager.darwinModules.home-manager
          ./modules/darwin
          ./nix-overlays.nix
        ];
      };
    };
}
