{ pkgs, ... }:

let
  ollama = "${pkgs.ollama}/bin/ollama";

  # Warcraft peon voice lines, vendored at build time so the Stop hook never
  # reaches the network.
  peonSounds = pkgs.stdenvNoCC.mkDerivation {
    name = "peon-sounds";
    src = pkgs.fetchFromGitHub {
      owner = "zupo";
      repo = "dotfiles";
      rev = "63c622b95e943f912a299cbb3ce535779d6f42a3";
      hash = "sha256-aiFhPJEZ3KfobrKkQ2PDF5M3ehNpFlcIIAAPKWA4ets=";
    };
    installPhase = ''
      mkdir -p $out
      cp sounds/*.ogg $out/
    '';
  };
in
{
  # Local coding model runtime for the Ollama + Aider agent. Aider supplies the
  # edit-capable harness; Ollama serves the model, bound to localhost only.
  # rtk is the token-killing CLI proxy wired into the Claude Code Bash hook below.
  home.packages = [
    pkgs.aider-chat
    pkgs.rtk
  ];

  services.ollama = {
    enable = true;
    host = "127.0.0.1";
    port = 11434;
  };

  # Pull qwen2.5-coder:7b after login, once the Ollama service is ready. Pulls
  # are idempotent, so re-running on every login is safe.
  launchd.agents.ollama-models = {
    enable = true;
    config = {
      Label = "dev.dz0ny.ollama-models";
      RunAtLoad = true;
      ProgramArguments = [
        "/bin/sh"
        "-c"
        ''
          for _ in $(seq 1 60); do
            ${ollama} list >/dev/null 2>&1 && break
            sleep 1
          done
          ${ollama} list >/dev/null 2>&1 || exit 0
          ${ollama} pull qwen2.5-coder:7b
        ''
      ];
    };
  };

  # Shared MCP servers, managed once here and consumed by each enabled agent
  # through its `enableMcpIntegration` option below.
  programs.mcp = {
    enable = true;

    servers = {
      # Current library and framework documentation.
      context7 = {
        url = "https://mcp.context7.com/mcp";
      };

      # Cloudflare Workers, platform, and product documentation.
      cloudflare-docs = {
        type = "http";
        url = "https://docs.mcp.cloudflare.com/mcp";
      };

      # Nixpkgs, nix-darwin, and Home Manager option/package lookup.
      nixos = {
        command = "nix";
        args = [
          "run"
          "github:utensils/mcp-nixos"
          "--"
        ];
      };
    };
  };

  # AI coding agents and their managed configuration.
  programs.claude-code = {
    enable = true;

    # Consume the shared MCP baseline defined above.
    enableMcpIntegration = true;

    settings = {
      env = {
        ANTHROPIC_DEFAULT_HAIKU_MODEL = "claude-sonnet-4-6[1m]";
        ANTHROPIC_DEFAULT_SONNET_MODEL = "claude-sonnet-4-6[1m]";
      };

      permissions.defaultMode = "auto";

      # Rewrite every Bash tool call through rtk before it runs, filtering and
      # compressing command output. Referenced by store path so the hook fires
      # even when the menu-bar app's minimal PATH lacks the HM profile.
      hooks.PreToolUse = [
        {
          matcher = "Bash";
          hooks = [
            {
              type = "command";
              command = "${pkgs.rtk}/bin/rtk hook claude";
            }
          ];
        }
      ];

      # Play a random Warcraft peon sound when Claude is waiting for input.
      hooks.Stop = [
        {
          hooks = [
            {
              type = "command";
              command = ''osascript -l JavaScript -e 'ObjC.import("AppKit"); var s = $.NSSound.alloc.initWithContentsOfFileByReference("'"$(ls ${peonSounds}/*.ogg | sort -R | head -1)"'", false); s.play(); while (s.isPlaying) { $.NSThread.sleepForTimeInterval(0.2); }' &'';
            }
          ];
        }
      ];

      enabledPlugins = {
        "frontend-design@claude-plugins-official" = true;
        "context7@claude-plugins-official" = true;
        "feature-dev@claude-plugins-official" = true;
        "commit-commands@claude-plugins-official" = true;
        "code-simplifier@claude-plugins-official" = true;
        "gopls-lsp@claude-plugins-official" = true;
        "swift-lsp@claude-plugins-official" = true;
        "devenv@devenv-claude" = true;
        "clangd-lsp@claude-plugins-official" = true;
        "hakuto@hakuto" = true;
        "cloudflare@claude-plugins-official" = true;
      };

      extraKnownMarketplaces.hakuto.source = {
        source = "github";
        repo = "teamniteo/hakuto";
      };

      effortLevel = "medium";
      tui = "fullscreen";
      skipDangerousModePermissionPrompt = true;
      theme = "auto";
      agentPushNotifEnabled = true;
      skipAutoPermissionPrompt = true;
    };

    context = ''
      @RTK.md
    '';
  };
}
