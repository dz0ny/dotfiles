## Overview
This is a nix-darwin + Home Manager flake managing a single Apple Silicon Mac mini named `Janezs-Mac-mini`, whose primary user is `dz0ny`. It's clearly tailored to a developer who lives in the terminal — the bulk of the effort goes into a polished zsh/Ghostty/git setup with a matching Catppuccin Mocha theme — while the macOS side is locked down and heavily customized for a specific personal workflow (Croatian keyboard, no Spotlight, no Time Machine).

- Nix itself is managed by **Determinate** (Determinate Nix), so `nix.enable = false` — nix-darwin does *not* manage the Nix daemon here.
- Build/apply with `darwin-rebuild switch --flake .#Janezs-Mac-mini`; format Nix files with `nix fmt` (`nixfmt-rfc-style`).
- Configuration is split into `modules/darwin/*.nix` (system) and `modules/home/dz0ny.nix` (user), plus a `.nixmac/` tree whose `data.json` files hold the editable data (Homebrew, SSH FDA check).

## Packages
Very little is installed at the system level; almost all day-to-day tooling comes through Home Manager for the `dz0ny` user, and GUI apps come through Homebrew.

- **System profile** (`modules/darwin/packages.nix` + flake): `vim`, `nixfmt-rfc-style`, and `syncthing` (the sync daemon binary, run as a per-user LaunchAgent — see Services).
- **User CLI tools** (`modules/home/dz0ny.nix`): `ripgrep` (`rg`), `fd`, `jq`, `yq-go` (`yq`), `htop`, and `devenv` for per-project dev shells (`devenv shell` / `devenv up`).
- **Program modules** that install a binary *and* wire up config: `fzf`, `bat`, `eza`, `zoxide`, `lazygit`, `starship`, `git` (with `delta` and `git-lfs`).

### Homebrew

Homebrew is enabled and managed by nix-darwin, but with `onActivation.cleanup = "none"` — meaning nix-darwin only *ensures* the declared packages are installed and never uninstalls anything you added manually with `brew`.

- The actual tap/brew/cask list lives in `.nixmac/homebrew/data.json` (read by `.nixmac/homebrew/default.nix`), which is not shown here.
- Some tools are deliberately kept on Homebrew rather than Nix: `gh` (the git credential helper references `/opt/homebrew/bin/gh` by absolute path) and `mise` (activated in the zsh startup). Ghostty.app is a Homebrew cask; only its config is managed by Nix.
- The services audit notes casks such as `setapp`, `zoom`, `privileges`, `orbstack`, `proton-drive`, and `tailscale` are expected to reinstall themselves and their launchd items on a fresh Mac.

## Fonts
One programming font is installed system-wide so the terminal renders icons correctly.

- `nerd-fonts.jetbrains-mono` — the JetBrainsMono Nerd Font, referenced by name in the Ghostty config (`font-family = JetBrainsMono Nerd Font`) and required for the glyphs used by `starship`, `eza` icons, and `lazygit`.
- Note the nixpkgs-unstable namespace: Nerd Fonts live under `nerd-fonts.*` now, not the old `nerdfonts.override` form.

## macOS Settings
A large, opinionated set of `system.defaults` in `modules/darwin/system-defaults.nix` reproduces this specific machine's preferences — only keys that differ from macOS factory defaults are recorded, so a rebuilt Mac comes up configured the same way.

### Input & keyboard

- Natural scrolling **off**; trackpad Force Click on with the lightest click thresholds; three-finger tap enabled.
- Very fast key repeat (`InitialKeyRepeat = 10`, `KeyRepeat = 1`) and press-and-hold accents disabled, so holding a key repeats it.
- Full keyboard access (`AppleKeyboardUIMode = 3`), ISO tilde key remapped (`system.keyboard.nonUS.remapTilde`).
- Input sources are **Croatian-PC** (primary) plus Slovenian, with the character palette and press-and-hold helpers — a re-login may be needed for a fresh Mac to reflect the active layout.
- Text replacements: `◊ → @` and `omw → On my way!`.

### Dock, Finder & windows

- Dock is **not** auto-hidden, sits on the **left** edge, tile size 78, no recent apps, minimize-into-app, and the bottom-right hot corner (Quick Note) is disabled.
- Pinned Dock apps, left→right: Arc, Mail, ChatGPT, Slack, Zed, Claude, Ghostty, Tailscale. Anything not in this list is cleared from the Dock on rebuild.
- Finder: list view, show all extensions and hidden dotfiles, path bar shown, full POSIX path in the title, new windows open in Home, folders sorted first, no disk icons on the desktop, and search defaults to the current folder.
- Window animations are effectively off (instant open/close/resize) and Stage Manager-style window grouping/auto-hide is tuned in `WindowManager`.

### Other

- Menu-bar clock shows day-of-week, date, and AM/PM.
- Screenshots have no window shadow, highlight clicks, and capture HDR; `.DS_Store` files are kept off network and USB volumes.
- Screensaver requires the password 10s after it starts.
- Magic Mouse is single-button.

## Services
There are almost no declared services — this module runs one hand-authored user agent and actively disables two macOS background facilities on every rebuild.

- **Syncthing** (`launchd.user.agents.syncthing`, `modules/darwin/services.nix`): nix-darwin has no high-level `services.syncthing` module, so the daemon from `pkgs.syncthing` is wired up as a per-user LaunchAgent (Label `io.syncthing.syncthing`) that runs `syncthing serve --no-browser --no-restart --gui-address=127.0.0.1:8384`. launchd supervises it (`KeepAlive`, `RunAtLoad`, `ProcessType = "Background"`, logs to `/tmp/syncthing.out.log` / `/tmp/syncthing.err.log`) — `--no-restart` hands restarts to launchd rather than Syncthing's own restarter. The web UI is bound to loopback only (`127.0.0.1:8384`), reachable at http://127.0.0.1:8384 from this Mac and never exposed on the network.
- On each activation, `system.activationScripts.disable-spotlight-and-time-machine` runs `mdutil -a -i off` / `mdutil -a -d` to fully disable Spotlight indexing, then `tmutil stopbackup` and `tmutil disable` to turn off Time Machine. The commands are idempotent. (Spotlight result categories are also all hidden in the defaults.)
- No high-level nix-darwin services (`tailscale`, `yabai`, etc.) are enabled, and no launchd daemons exist.
- Per the captured audit (2026-07-11), every non-Apple launchd item — Setapp, Google Keystone, Zoom, Privileges, OrbStack, Proton Drive, Tailscale, Determinate Nix — is installed and managed by its own app/cask, so nothing needs to be declared here. Re-run `scripts/capture-state.sh` to refresh that audit.

## Shell & Environment
The interactive shell is a fully-featured zsh managed by Home Manager, themed to match Ghostty, and this is where most of the daily UX lives.

### zsh

- Autosuggestions, syntax highlighting, and completion are on; history holds 50 000 shared, de-duplicated entries.
- The startup (`initContent`) bootstraps **bun** (adds `~/.bun/bin` to `PATH`) and activates **mise** from `~/.local/bin/mise`. `mise` is installed via Homebrew, and its global toolchain is pinned in `~/.config/mise/config.toml` to `flutter = "latest"` (run `mise install` on a fresh Mac).
- `environment.variables` (`modules/darwin/environment.nix`) is empty — no system-wide env vars are set.

### Aliases & tools

- `lg` → `lazygit`; `ls`/`ll`/`la`/`lt` come from **eza** (with git status and auto icons).
- **fzf** keybindings: `Ctrl-R` history, `Ctrl-T` files, `Alt-C` cd — all backed by `fd` so hidden files are found and `.gitignore` respected.
- **zoxide** provides `z` / `zi` for smart directory jumping; **bat** replaces `cat` with Catppuccin-mocha highlighting.
- **starship** renders a two-line Catppuccin Mocha prompt. Note it's built from a custom override that drops desktop notifications (the `notify` feature breaks the Darwin linker), keeping only the `battery` feature.

### Ghostty

- The terminal itself is a Homebrew cask; only `~/.config/ghostty/config` is managed here: `catppuccin-mocha` theme, JetBrainsMono Nerd Font at size 14, block cursor, `copy-on-select`, `macos-option-as-alt`, and generous padding/line spacing.

## Security & Secrets
Security here is a mix of enabled macOS hardening, a hardened SSH client, and a sops-nix scaffold that currently holds no actual secrets.

### System hardening

- **Touch ID for sudo** is enabled (`security.pam.services.sudo_local.touchIdAuth`), so `sudo` and `darwin-rebuild` accept a fingerprint.
- The **application firewall** is on with **stealth mode** (`modules/darwin/networking.nix`).
- Downloaded-app **quarantine** is kept on (`LSQuarantine = true`).

### SSH client

Home Manager owns `~/.ssh/config` (the previous file is backed up as `*.hm-backup` on first activation). It defines:

- Modern, post-quantum-forward crypto defaults (sntrup761x25519, chacha20-poly1305, etc.), agent keys added on first use and passphrases loaded from the **macOS Keychain**, hashed known-hosts, and connection multiplexing over `~/.ssh/sockets` (created automatically by an activation hook).
- Host aliases tagged `personal` (`rpi`, `gh`, `github.com`) or `work` (`air`), with `Match tagged` blocks selecting the identity — both realms currently use `~/.ssh/id_ed25519` (a dedicated work key is a noted TODO).
- A self-contained `linux-builder` host on `localhost:31022` using `/etc/nix/builder_ed25519`.
- `Include`s for OrbStack (`~/.orbstack/ssh/config`) and Colima (`~/.colima/ssh_config`).

### Git commit signing

- Commits are signed with **SSH signatures** using `~/.ssh/id_ed25519.pub`, but `signByDefault = false` (tags are not signed).
- `~/.config/git/allowed_signers` is written declaratively so `git log --show-signature` can verify your own commits locally.
- GitHub auth uses `gh` as the credential helper via its absolute Homebrew path.

### sops-nix

- The sops-nix scaffold is wired in and looks for an age key at `$SOPS_AGE_KEY_FILE`, then `~/Library/Application Support/sops/age/keys.txt`, then `~/.config/sops/age/keys.txt` — falling back to `null` if none exist.
- **No secrets are actually declared** — `sops.secrets` in `sops-secrets.nix` is empty, so this is ready-to-use plumbing rather than an active secret store.

### SSH Full Disk Access check

- The `.nixmac/ssh-fda` module adds a pre-activation check: if you run `darwin-rebuild` over SSH without Full Disk Access, it warns that app updates may fail (enable it under **System Settings → General → Sharing → Remote Login**, or rebuild from a local terminal). It's a warning by default; a `strict` flag (in `.nixmac/ssh-fda/data.json`) would make it abort instead.