{ config, pkgs, ... }:

{
  # Fonts module
  # Purpose:
  # - Install fonts available from nixpkgs into the system so GUI applications
  #   and terminal environments can use them.
  #
  # Usage notes:
  # - Add fonts using `with pkgs; [ ... ]` and include a short comment for
  #   each font explaining why it's included (e.g. "programming font").
  # - On macOS, font caches may need rebuilding after changes; document any
  #   manual steps here if required by other tooling.
  #
  fonts.packages = with pkgs; [
    # Programming font used by Ghostty (see modules/home/dz0ny.nix). The Nerd
    # Font variant bundles glyphs used by lazygit.
    # NOTE: on nixpkgs-unstable Nerd Fonts are namespaced under `nerd-fonts.*`
    # (the old `nerdfonts.override { fonts = [...]; }` was removed).
    nerd-fonts.jetbrains-mono
  ];

  # Document any macOS-specific font handling or pitfalls here for future
  # automation. For example, if a font must be installed via Homebrew cask
  # instead of nixpkgs, note that here and why.
}
