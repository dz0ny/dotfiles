{ pkgs, lib, ... }:

# Home Manager configuration for the primary user `dz0ny`.
#
# Purpose:
# - Own the daily-coding terminal declaratively: shell, git, and the CLI
#   toolkit used constantly (fzf, ripgrep, fd, bat, eza, zoxide, jq, yq, htop,
#   lazygit, devenv).
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
    yq-go # YAML/XML/TOML processor (yq)
    htop # interactive process viewer
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

    # `ls`/`ll`/`la`/`lt` are provided by the eza module below (zsh integration).
    shellAliases = {
      lg = "lazygit";
    };

    # Preserve the user's existing shell bootstrap (mise + bun). The fzf hook is
    # injected automatically by its program module below, so it is intentionally
    # not repeated here.
    initContent = ''
      # Homebrew bin on PATH so Homebrew-only CLIs (e.g. heroku from the
      # heroku/brew tap, see .nixmac/homebrew/data.json) are reachable. Appended,
      # not prepended, so nix-managed tools keep priority over any Homebrew ones.
      if [ -d /opt/homebrew/bin ]; then
        export PATH="$PATH:/opt/homebrew/bin"
      fi

      # bun
      export BUN_INSTALL="$HOME/.bun"
      export PATH="$BUN_INSTALL/bin:$PATH"
      [ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

      # mise — runtime version manager
      if [ -x "$HOME/.local/bin/mise" ]; then
        eval "$("$HOME/.local/bin/mise" activate zsh)"
      fi

      # fzf history on Alt-R (⌥R) instead of Ctrl-R. Ctrl-R is unreliable across
      # terminals/multiplexers (often swallowed as a redraw/flow-control key),
      # so move fzf's history widget to ⌥R — which Ghostty emits as a clean
      # `^[r` escape thanks to macos-option-as-alt = true — and hand Ctrl-R back
      # to zsh's native incremental reverse-search as a fallback. This runs after
      # the fzf zsh integration (injected earlier by programs.fzf), so the
      # fzf-history-widget already exists.
      bindkey '^[r' fzf-history-widget
      bindkey '^r'  history-incremental-search-backward
    '';
  };

  # ---------------------------------------------------------------------------
  # starship — cross-shell prompt
  # ---------------------------------------------------------------------------
  # The zsh integration hook is injected automatically (enableZshIntegration
  # defaults to true), so nothing extra is needed in the zsh initContent above.
  # Theme matches Ghostty's Catppuccin Mocha; symbols assume the JetBrainsMono
  # Nerd Font already configured for the terminal.
  programs.starship = {
    enable = true;
    # Build without the default `notify` feature. It pulls in `notify-rust` ->
    # `mac-notification-sys`, whose AppKit/Foundation link step crashes the
    # cctools linker on this Darwin toolchain (ld Trace/BPT trap: 5), which
    # breaks the whole system build. Desktop notifications aren't used here, so
    # keep only `battery` from the default feature set.
    package = pkgs.starship.overrideAttrs (old: {
      cargoBuildNoDefaultFeatures = true;
      cargoBuildFeatures = [ "battery" ];
      cargoCheckNoDefaultFeatures = true;
      cargoCheckFeatures = [ "battery" ];
    });
    settings = {
      palette = "catppuccin_mocha";
      add_newline = true;

      # Two lines: a powerline info bar, then the input caret. Segments are
      # colored blocks joined by  (Nerd Font powerline separators); each
      # segment paints its background and borrows the next segment's color as
      # its own separator foreground so the blocks flow into one another.
      format = lib.concatStrings [
        "[](surface0)"
        "$os"
        "$directory"
        "[](fg:surface0 bg:mauve)"
        "$git_branch"
        "$git_status"
        "[](fg:mauve bg:sky)"
        "$nix_shell"
        "[](fg:sky bg:surface0)"
        "$cmd_duration"
        "[](surface0)"
        "$line_break"
        "$character"
      ];

      character = {
        success_symbol = "[❯](green)";
        error_symbol = "[❯](red)";
        vimcmd_symbol = "[❮](green)";
      };

      os = {
        disabled = false;
        style = "bg:surface0 fg:text";
        format = "[ $symbol ]($style)";
        symbols.Macos = "";
      };

      directory = {
        style = "bg:surface0 fg:blue";
        format = "[ $path ]($style)";
        truncation_length = 4;
        truncate_to_repo = true;
        truncation_symbol = "…/";
        read_only = " 󰌾";
        read_only_style = "bg:surface0 fg:red";
      };

      git_branch = {
        symbol = "";
        style = "bg:mauve fg:crust";
        format = "[ $symbol $branch ]($style)";
      };
      git_status = {
        style = "bg:mauve fg:crust";
        format = "[($all_status$ahead_behind )]($style)";
      };

      nix_shell = {
        symbol = "";
        style = "bg:sky fg:crust";
        format = "[ $symbol $name ]($style)";
      };

      cmd_duration = {
        min_time = 2000;
        style = "bg:surface0 fg:yellow";
        format = "[  $duration ]($style)";
      };

      palettes.catppuccin_mocha = {
        rosewater = "#f5e0dc";
        flamingo = "#f2cdcd";
        pink = "#f5c2e7";
        mauve = "#cba6f7";
        red = "#f38ba8";
        maroon = "#eba0ac";
        peach = "#fab387";
        yellow = "#f9e2af";
        green = "#a6e3a1";
        teal = "#94e2d5";
        sky = "#89dceb";
        sapphire = "#74c7ec";
        blue = "#89b4fa";
        lavender = "#b4befe";
        text = "#cdd6f4";
        surface0 = "#313244";
        crust = "#11111b";
      };
    };
  };

  # ---------------------------------------------------------------------------
  # fzf — fuzzy finder (Alt-R history, Ctrl-T files, Alt-C cd)
  # History is rebound from Ctrl-R to Alt-R in the zsh initContent above.
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
  # bat — cat(1) clone with syntax highlighting
  # ---------------------------------------------------------------------------
  programs.bat = {
    enable = true;
    config.theme = "Catppuccin-mocha"; # matches the Ghostty / starship theme
  };

  # ---------------------------------------------------------------------------
  # eza — modern ls(1) replacement
  # ---------------------------------------------------------------------------
  # enableZshIntegration adds ls/ll/la/lt aliases pointing at eza. This
  # supersedes the hand-rolled `ll` alias in the zsh block above (eza wins
  # since the module aliases are appended after shellAliases).
  programs.eza = {
    enable = true;
    git = true;
    icons = "auto"; # requires the Nerd Font already set in Ghostty
  };

  # ---------------------------------------------------------------------------
  # zoxide — smarter cd that learns your most-used directories (z / zi)
  # ---------------------------------------------------------------------------
  # The zsh hook is injected automatically (enableZshIntegration defaults true).
  programs.zoxide.enable = true;

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

    # git-delta — syntax-highlighting pager for `git diff`/`show`/`log -p`.
    # Enabling it installs the `delta` binary and wires it as core.pager +
    # interactive.diffFilter (for `git add -p`).
    delta = {
      enable = true;
      options = {
        navigate = true; # n/N to jump between diff hunks
        line-numbers = true;
        syntax-theme = "Catppuccin-mocha"; # matches bat / starship / Ghostty
      };
    };

    # git-lfs — large file storage. Enabling installs the binary and adds the
    # required `filter.lfs` smudge/clean/process config.
    lfs.enable = true;

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
  # ssh — hardened client config (~/.ssh/config)
  # ---------------------------------------------------------------------------
  # Home Manager now owns ~/.ssh/config; the previous hand-written file is
  # backed up on first activation (home-manager.backupFileExtension). Design:
  #   * enableDefaultConfig = false — opt out of HM's soon-to-be-deprecated
  #     built-in `Host *` defaults so `settings."*"` below is the single source
  #     of global defaults (otherwise both fight and HM warns).
  #   * includes — the OrbStack and Colima helper configs are re-emitted via a
  #     single `Include` at the very top of the file (before any Host block),
  #     which is exactly where OrbStack requires its include to sit.
  #   * Each short host alias carries a `Tag` (work | personal); the two
  #     `Match tagged …` blocks below attach the right identity + agent policy
  #     per realm. ssh sets Tag when the alias block matches and only then
  #     evaluates `Match tagged`, so the alias blocks must be emitted first —
  #     hence the DAG ordering (lib.hm.dag.entryAfter hostAliases).
  #   * ssh_config is first-value-wins, so host/match blocks (emitted before
  #     `*`) override the global `*` defaults where they overlap.
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    includes = [
      "~/.orbstack/ssh/config" # OrbStack Linux machines (the `orb` host)
      "~/.colima/ssh_config" # Colima VM
    ];

    settings =
      let
        # Modern, post-quantum-forward crypto (macOS ships OpenSSH 10.x).
        modernKex = [
          "sntrup761x25519-sha512@openssh.com"
          "curve25519-sha256"
          "curve25519-sha256@libssh.org"
          "diffie-hellman-group18-sha512"
          "diffie-hellman-group16-sha512"
        ];
        modernCiphers = [
          "chacha20-poly1305@openssh.com"
          "aes256-gcm@openssh.com"
          "aes128-gcm@openssh.com"
          "aes256-ctr"
        ];
        modernMACs = [
          "hmac-sha2-512-etm@openssh.com"
          "hmac-sha2-256-etm@openssh.com"
          "umac-128-etm@openssh.com"
        ];
        pubkeyAlgos = [
          "ssh-ed25519"
          "ssh-ed25519-cert-v01@openssh.com"
          "sk-ssh-ed25519@openssh.com"
          "sk-ssh-ed25519-cert-v01@openssh.com"
          "rsa-sha2-512"
          "rsa-sha2-256"
        ];

        # `Match tagged …` blocks must be emitted after every tagged alias.
        hostAliases = [
          "rpi"
          "gh"
          "github.com"
          "air"
          "linux-builder"
        ];
      in
      {
        # --- short aliases: personal ---
        "rpi" = {
          HostName = "rpi.local";
          User = "dz0ny";
          Tag = "personal";
        };
        "gh" = {
          HostName = "github.com";
          User = "git";
          Tag = "personal";
        };
        # Canonical github.com so plain `git@github.com:…` remotes match too.
        "github.com" = {
          User = "git";
          Tag = "personal";
        };

        # --- short aliases: work ---
        "air" = {
          HostName = "air.radioterminal.si";
          User = "dz0ny";
          Tag = "work";
        };

        # --- nix linux-builder: self-contained, dedicated key ---
        "linux-builder" = {
          HostName = "localhost";
          User = "builder";
          Port = 31022;
          HostKeyAlias = "linux-builder";
          IdentityFile = "/etc/nix/builder_ed25519";
          IdentitiesOnly = true;
        };

        # --- per-realm identity + agent policy (Match blocks) ---
        "match-personal" = lib.hm.dag.entryAfter hostAliases {
          header = "Match tagged personal";
          IdentityFile = "~/.ssh/id_ed25519";
          IdentitiesOnly = true;
        };
        "match-work" = lib.hm.dag.entryAfter hostAliases {
          header = "Match tagged work";
          # TODO: swap in a dedicated work key when one is provisioned; for now
          # work reuses the personal ed25519 key so existing hosts keep working.
          IdentityFile = "~/.ssh/id_ed25519";
          IdentitiesOnly = true;
        };

        # --- global defaults (rendered last; earlier blocks win on overlap) ---
        "*" = {
          AddKeysToAgent = "yes"; # add keys to the agent on first use
          UseKeychain = true; # load key passphrases from the macOS Keychain
          ForwardAgent = false; # never forward the agent by default
          HashKnownHosts = true; # hash hostnames/IPs in ~/.ssh/known_hosts
          Compression = false;
          ServerAliveInterval = 60;
          ServerAliveCountMax = 3;
          ControlMaster = "auto"; # multiplex connections…
          ControlPath = "~/.ssh/sockets/%C"; # …over a short hashed socket name
          ControlPersist = "10m";
          StrictHostKeyChecking = "ask";
          VerifyHostKeyDNS = "ask";
          KexAlgorithms = modernKex;
          Ciphers = modernCiphers;
          MACs = modernMACs;
          HostKeyAlgorithms = pubkeyAlgos;
          PubkeyAcceptedAlgorithms = pubkeyAlgos;
        };
      };
  };

  # ControlMaster multiplexing socket directory (ssh will not create it).
  home.activation.sshSocketDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p $VERBOSE_ARG "$HOME/.ssh/sockets"
    run chmod 700 "$HOME/.ssh/sockets"
  '';

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
  # .nixmac/homebrew/data.json). We only own its config here so the font +
  # appearance are declarative. No `theme` is set, so Ghostty uses its default
  # colors; the aesthetics block below defines a translucent, blurred black
  # background. The starship powerline prompt is background-independent (each
  # segment paints its own bg/fg), so it stays readable regardless.
  home.file.".config/ghostty/config".text = ''
    font-family = JetBrainsMono Nerd Font

    # aesthetics
    background-opacity = 0.85
    background-blur = 16
    background = #000000

    # Full macOS window chrome: real titlebar with traffic lights, so the window
    # can be dragged, minimized and zoomed like any other app.
    window-decoration = auto
    macos-titlebar-style = native

    # typography
    font-size = 16
    font-thicken = true
    font-thicken-strength = 1
    adjust-cell-height = 1

    # Comfortable reading: inner padding.
    window-padding-x = 12
    window-padding-y = 12
    window-padding-balance = true

    cursor-style = block
    cursor-style-blink = false
    mouse-hide-while-typing = true

    macos-option-as-alt = true
    clipboard-read = allow
    copy-on-select = clipboard
    confirm-close-surface = false

    # keybinds: match browser tab navigation. Ghostty binds cmd+opt+arrows to
    # split focus by default; splits stay reachable via cmd+[ / cmd+].
    keybind = super+alt+left=previous_tab
    keybind = super+alt+right=next_tab

    # cmd+shift+d splits the current surface to the right.
    keybind = super+shift+d=new_split:right
  '';
}
