{ ... }:

{
  # Home Manager, wired through nix-darwin. The actual per-user configuration
  # lives in modules/home/ (split by Configure section) to keep this file to
  # just the plumbing.
  #
  # Enabled to manage the daily-coding terminal declaratively (zsh, devenv,
  # git signing, fzf, lazygit, ripgrep, fd, jq, Ghostty config).
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;

    # On first activation Home Manager will refuse to clobber pre-existing
    # hand-written dotfiles (~/.zshrc, ~/.gitconfig). This makes it move them
    # aside to `<file>.hm-backup` instead of erroring out.
    backupFileExtension = "hm-backup";

    users.dz0ny = import ../home;
  };
}
