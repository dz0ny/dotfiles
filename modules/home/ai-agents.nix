{ pkgs, ... }:

let
  ollama = "${pkgs.ollama}/bin/ollama";
in
{
  # Local coding model runtime for the Ollama + Aider agent. Aider supplies the
  # edit-capable harness; Ollama serves the model, bound to localhost only.
  home.packages = [ pkgs.aider-chat ];

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

      hooks.PreToolUse = [
        {
          matcher = "Bash";
          hooks = [
            {
              type = "command";
              command = "rtk hook claude";
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
