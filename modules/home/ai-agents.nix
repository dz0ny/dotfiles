{ ... }:

{
  # AI coding agents and their managed configuration.
  programs.claude-code = {
    enable = true;

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
