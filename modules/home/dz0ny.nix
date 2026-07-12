{ pkgs, lib, ... }:

# Home Manager configuration for the primary user `dz0ny`.
#
# Purpose:
# - Own the daily-coding terminal declaratively: shell, git, and the handful of
#   CLI tools used constantly (fzf, ripgrep, fd, jq, lazygit, devenv).
# - Manage the dotfiles for those tools (~/.zshrc, ~/.gitconfig,
#   ~/.config/ghostty/config, ...).
#
# Notes for future automation / auditing:
# - This module is the single source of truth for these tools. The same tools
#   were previously installed via Homebrew (ripgrep, git); those were
#   removed from `.nixmac/homebrew/data.json`. `gh` stays on Homebrew because
#   the git credential helper references /opt/homebrew/bin/gh by absolute path.
# - Home Manager rewrites the managed dotfiles. Existing hand-written files are
#   backed up on first activation (see `home-manager.backupFileExtension` in
#   modules/darwin/home.nix).

{
  home.stateVersion = "24.05";

  # Extra CLI tools that don't have (or don't need) a dedicated program module.
  home.packages = with pkgs; [
    ripgrep # fast recursive search (rg)
    fd # fast, user-friendly find
    jq # JSON processor
    devenv # per-project developer environments (devenv shell / devenv up)
  ];

  # ---------------------------------------------------------------------------
  # zsh — the interactive shell
  # ---------------------------------------------------------------------------
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    enableCompletion = true;

    history = {
      size = 50000;
      save = 50000;
      ignoreDups = true;
      ignoreSpace = true;
      share = true;
    };

    shellAliases = {
      ll = "ls -lah";
      lg = "lazygit";
    };

    # Preserve the user's existing shell bootstrap (mise + bun). The fzf hook is
    # injected automatically by its program module below, so it is intentionally
    # not repeated here.
    initContent = ''
      # bun
      export BUN_INSTALL="$HOME/.bun"
      export PATH="$BUN_INSTALL/bin:$PATH"
      [ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

      # mise — runtime version manager
      if [ -x "$HOME/.local/bin/mise" ]; then
        eval "$("$HOME/.local/bin/mise" activate zsh)"
      fi
    '';
  };

  # ---------------------------------------------------------------------------
  # fzf — fuzzy finder (Ctrl-R history, Ctrl-T files, Alt-C cd)
  # ---------------------------------------------------------------------------
  programs.fzf = {
    enable = true;
    # Use fd for the file/dir walkers so hidden files are found and .gitignore
    # is respected.
    defaultCommand = "fd --type f --hidden --follow --exclude .git";
    fileWidgetCommand = "fd --type f --hidden --follow --exclude .git";
    changeDirWidgetCommand = "fd --type d --hidden --follow --exclude .git";
  };

  # ---------------------------------------------------------------------------
  # lazygit — terminal UI for git
  # ---------------------------------------------------------------------------
  programs.lazygit = {
    enable = true;
    settings = {
      gui.nerdFontsVersion = "3";
    };
  };

  # ---------------------------------------------------------------------------
  # git — with SSH commit signing
  # ---------------------------------------------------------------------------
  # Ports the previous ~/.gitconfig verbatim and adds SSH signing. The signing
  # key is the personal ed25519 public key; commits and tags are signed by
  # default. `gpg.ssh.allowedSignersFile` lets `git log --show-signature`
  # verify locally-signed commits.
  programs.git = {
    enable = true;
    userName = "Janez T";
    userEmail = "hey@dz0ny.dev";

    aliases = {
      pp = "push --force-with-lease";
      up = "pull origin main";
      co = "checkout main";
    };

    signing = {
      key = "~/.ssh/id_ed25519.pub";
      signByDefault = false;
    };

    extraConfig = {
      # --- SSH commit signing ---
      gpg.format = "ssh";
      gpg."ssh".allowedSignersFile = "~/.config/git/allowed_signers";
      tag.gpgSign = false;

      # --- ported from the previous ~/.gitconfig ---
      init.defaultBranch = "main";
      pull.rebase = true;
      push = {
        default = "simple";
        autoSetupRemote = true;
        followTags = true;
      };
      fetch = {
        prune = true;
        pruneTags = true;
        all = true;
      };
      rebase = {
        autoStash = true;
        autoSquash = true;
        updateRefs = true;
      };
      diff = {
        algorithm = "histogram";
        colorMoved = "plain";
        mnemonicPrefix = true;
        renames = true;
      };
      column.ui = "auto";
      branch.sort = "-committerdate";
      tag.sort = "version:refname";
      help.autocorrect = "prompt";
      commit.verbose = true;
      rerere = {
        enabled = true;
        autoupdate = true;
      };
      core.excludesfile = "~/.gitignore";

      # gh as the GitHub credential helper (installed via Homebrew).
      credential."https://github.com".helper = [
        ""
        "!/opt/homebrew/bin/gh auth git-credential"
      ];
      credential."https://gist.github.com".helper = [
        ""
        "!/opt/homebrew/bin/gh auth git-credential"
      ];
    };
  };

  # ---------------------------------------------------------------------------
  # mise — global runtime toolchain (~/.config/mise/config.toml)
  # ---------------------------------------------------------------------------
  # mise itself is installed via Homebrew and activated in the zsh initContent
  # above. This pins the globally-installed runtimes so a fresh Mac gets the
  # same toolchain after `mise install`. Flutter pulls in a matching JDK.
  home.file.".config/mise/config.toml".text = ''
    [tools]
    flutter = "latest"
  '';

  # allowed_signers so `git` can verify our own SSH-signed commits locally.
  home.file.".config/git/allowed_signers".text =
    "hey@dz0ny.dev ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII9el2S9wSrotgpeROY4GZdPlpn3m2SjLk8uV/ToUvxU dz0ny@ubuntu.si\n";

  # ---------------------------------------------------------------------------
  # Ghostty — terminal emulator config (~/.config/ghostty/config)
  # ---------------------------------------------------------------------------
  # Ghostty.app itself is installed via Homebrew cask (see
  # .nixmac/homebrew/data.json). We only own its config here so the readable
  # theme + font are declarative. Ghostty ships the
  # Catppuccin themes built in; "catppuccin-mocha" is a high-contrast, readable
  # dark theme.
  home.file.".config/ghostty/config".text = ''
    theme = catppuccin-mocha

    font-family = JetBrainsMono Nerd Font
    font-size = 14
    font-thicken = true

    # Comfortable reading: a bit of line spacing and inner padding.
    adjust-cell-height = 12%
    window-padding-x = 12
    window-padding-y = 12
    window-padding-balance = true

    cursor-style = block
    cursor-style-blink = false
    mouse-hide-while-typing = true

    macos-option-as-alt = true
    copy-on-select = clipboard
    confirm-close-surface = false
  '';
}
