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
