{ ... }:

{
  # Shared MCP servers, managed once here and consumed by each enabled agent
  # through its `enableMcpIntegration` option (see ai-agents.nix).
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
}
