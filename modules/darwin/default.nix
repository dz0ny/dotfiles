{ ... }:

{
  imports = [
    ./packages.nix
    ./fonts.nix
    ./macos-settings.nix
    ./services.nix
    ./security-secrets.nix
    ./shell-environment.nix

    # Supporting system wiring for the section modules.
    ./networking.nix
    ./sops.nix
    ./sops-secrets.nix
    ./users.nix
    ./home.nix
  ];
}
