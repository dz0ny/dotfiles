{ config, pkgs, ... }:

{
  # ============================================================
  # Services and Launchd Jobs Module
  # ============================================================
  #
  # Purpose:
  # - Centralized management of system services and launchd jobs.
  #
  # Key concepts:
  # - `services`: High-level modules (e.g., tailscale, skhd, yabai).
  # - `launchd.daemons`: System-wide (Root) jobs.
  # - `launchd.user.agents`: Per-user jobs (runs only when logged in).
  #
  # Note: StartCalendarInterval and similar keys are UpperCamelCase (Apple plist standard).
  #

  # ------------------------------------------------------------
  # High-level services
  # ------------------------------------------------------------
  services = {
    # Example: nix-darwin managed services
    # tailscale.enable = true;
    # yabai.enable = true;
  };

  # ------------------------------------------------------------
  # Syncthing (continuous folder sync)
  # ------------------------------------------------------------
  # nix-darwin has no high-level `services.syncthing` module, so Syncthing is
  # wired up as a per-user LaunchAgent instead. The binary comes from
  # `pkgs.syncthing` (declared in packages.nix). The daemon keeps folders in
  # sync with this user's other devices and launchd restarts it via KeepAlive.
  #
  # The web UI is bound to 127.0.0.1:8384 (loopback only) so it is never
  # exposed on the network; reach it at http://127.0.0.1:8384 from this Mac.
  # `--no-browser` stops it from opening a browser on start and `--no-restart`
  # hands process supervision to launchd rather than Syncthing's own restarter.
  launchd.user.agents.syncthing = {
    serviceConfig = {
      Label = "io.syncthing.syncthing";
      ProgramArguments = [
        "${pkgs.syncthing}/bin/syncthing"
        "serve"
        "--no-browser"
        "--no-restart"
        "--gui-address=127.0.0.1:8384"
      ];
      KeepAlive = true;
      RunAtLoad = true;
      ProcessType = "Background";
      StandardOutPath = "/tmp/syncthing.out.log";
      StandardErrorPath = "/tmp/syncthing.err.log";
    };
  };

  # Disable both macOS background facilities whenever the configuration is
  # activated. `mdutil -d` disables all Spotlight activity, while `-i off`
  # also records indexing as disabled for every available volume. Time Machine
  # is stopped first in case a backup is running, then automatic backups are
  # disabled. The commands are idempotent.
  system.activationScripts.disable-spotlight-and-time-machine.text = ''
    echo >&2 "disabling Spotlight and Time Machine..."
    /usr/bin/mdutil -a -i off || true
    /usr/bin/mdutil -a -d || true
    /usr/bin/tmutil stopbackup || true
    /usr/bin/tmutil disable
  '';

  # ------------------------------------------------------------
  # launchd audit (captured 2026-07-11 from Janezs-Mac-mini)
  # ------------------------------------------------------------
  # A full sweep of the live machine (~/Library/LaunchAgents,
  # /Library/Launch{Agents,Daemons}, and `launchctl list`) found NO
  # hand-authored user launchd jobs. Every non-Apple launchd item belongs to
  # an application that installs and manages its own plist:
  #
  #   Setapp            com.setapp.DesktopClient.*   (cask "setapp")
  #   Google Keystone   com.google.keystone.*        (Chrome/Google casks)
  #   Zoom              us.zoom.*                     (cask "zoom")
  #   Privileges        corp.sap.privileges.*         (cask "privileges")
  #   OrbStack          dev.orbstack.*                (cask "orbstack")
  #   Proton Drive      ch.protonmail.drive.*         (cask "proton-drive")
  #   Tailscale         io.tailscale.ipn.*            (cask "tailscale")
  #   Determinate Nix   systems.determinate.* / org.nixos.activate-system
  #
  # Login items (Pareto Security, Stats, Raycast, Android File Transfer Agent)
  # are likewise registered by the apps themselves via SMAppService, not by
  # nix-darwin. All of these reappear automatically once the corresponding
  # Homebrew casks (see .nixmac/homebrew/data.json) are installed on a
  # replacement Mac, so there is nothing to declare here. Re-run
  # `scripts/capture-state.sh` to refresh this audit.

  # ------------------------------------------------------------
  # System-wide LaunchDaemons (runs as root)
  # ------------------------------------------------------------
  # launchd.daemons = {
  #   rebootSunday = {
  #     script = ''
  #       /sbin/shutdown -r now
  #     '';
  #     serviceConfig = {
  #       Label = "org.nix-darwin.rebootSunday";
  #       StartCalendarInterval = [
  #         { Weekday = 0; Hour = 3; Minute = 0; }
  #       ];
  #       RunAtLoad = false;
  #     };
  #   };
  # };

  # ------------------------------------------------------------
  # Per-user LaunchAgents (runs as ${USER})
  # ------------------------------------------------------------
  # launchd.user.agents = {
  #   # Example: User-level Nix garbage collection
  #   nix-gc-user = {
  #     serviceConfig = {
  #       Label = "org.nix-darwin.nix-gc-user";
  #       ProgramArguments = [
  #         "${pkgs.nix}/bin/nix-collect-garbage"
  #         "--delete-older-than"
  #         "30d"
  #       ];
  #       StartCalendarInterval = [
  #         { Hour = 10; Minute = 0; } # Daily at 10am
  #       ];
  #       RunAtLoad = true;
  #       StandardOutPath = "/tmp/nix-gc-user.out.log";
  #       StandardErrorPath = "/tmp/nix-gc-user.err.log";
  #     };
  #   };

  #   # Example: Running a custom shell script
  #   cleanup-logs = {
  #     script = ''
  #       find /Users/Shared/Logs -name "*.log" -mtime +7 -delete
  #     '';
  #     serviceConfig = {
  #       Label = "org.nix-darwin.cleanup-logs";
  #       StartCalendarInterval = [
  #         { Weekday = 6; Hour = 23; Minute = 59; }
  #       ];
  #     };
  #   };
  # };
}
