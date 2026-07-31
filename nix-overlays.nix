{
  lib,
  pkgs,
  inputs,
  ...
}:

{
  # Nixpkgs overlays
  # Purpose:
  # - Provide a central place to define overlays that modify or extend
  #   packages from `nixpkgs` for this machine.
  #
  # Usage notes:
  # - Each overlay has the form: `self: super: { <pkg> = ...; }`.
  # - Overlays are useful for:
  #   - Patching a package with local fixes
  #   - Adding a custom package built from a local directory
  #   - Adjusting package defaults for the system
  #
  # Example overlay (commented):
  # (self: super: {
  #   myCustomGit = super.callPackage ./packages/my-git { };
  # })

  nixpkgs.overlays = [
    # devenv from the upstream release flake (pinned in flake.nix) rather than
    # the nixpkgs snapshot, which trails upstream by a release or two. Anything
    # referring to `pkgs.devenv` — see modules/home/shell-environment.nix —
    # gets the pinned version, including under Home Manager
    # (`useGlobalPkgs = true` means it shares this pkgs instance).
    (final: prev: {
      devenv = inputs.devenv.packages.${prev.stdenv.hostPlatform.system}.devenv;
    })
  ];

  # Allow the single unfree package we install declaratively — Claude Code
  # (Anthropic's CLI, installed via programs.claude-code in
  # modules/home/dz0ny.nix). Scope the exception to just that package so the
  # rest of the system stays free-only instead of flipping `allowUnfree` on
  # globally. `useGlobalPkgs = true` means Home Manager inherits this config.
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [ "claude-code" ];
}
