{ config, pkgs, ... }:

{
  # System packages module
  # Purpose:
  # - Declare packages that should be present in the global system profile.
  # - Use this for CLI tools and utilities you want available to all users.
  #
  # Notes for usage and automation:
  # - Prefer adding packages here that are architecture-independent or
  #   machine-global. For user-specific packages, consider `home-manager`.
  # - When adding a package, comment why it is required to aid future
  #   automation or auditing.
  # - If you need a custom build or patched package, add an overlay in
  #   `nix-overlays.nix` and reference that package here.
  #
  # Example commands to preview changes:
  # $ darwin-rebuild build --flake .#Scotts-MacBook-Pro-2
  # $ darwin-rebuild switch --flake .#Scotts-MacBook-Pro-2

  environment.systemPackages = with pkgs; [
    nixfmt-rfc-style # official RFC 166 Nix code formatter (also wired up as `nix fmt`)
    syncthing # continuous folder sync daemon (run as a per-user LaunchAgent in services.nix)
  ];

  # If you prefer per-user profiles, consider using `home-manager` instead
  # of placing everything in the global system profile.
}
