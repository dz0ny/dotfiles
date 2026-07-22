## Overview
This is a nix-darwin + Home Manager configuration for a single Apple Silicon Mac mini named `Janezs-Mac-mini`, owned and used by `dz0ny` (Janez T, `hey@dz0ny.dev`). It's tailored for a security-conscious daily-coding setup: a hardened, Pareto-Security-style macOS posture layered on top of a fully declarative terminal, git, and AI-agent toolkit. Nix itself is managed by Determinate (`nix.enable = false`), so nix-darwin only ensures packages, defaults, Homebrew casks, and launchd jobs — it does not manage the Nix daemon.

Everything is built and applied with `darwin-rebuild switch --flake .#Janezs-Mac-mini`. The flake pulls in `nixpkgs-unstable`, `nix-darwin`, `sops-nix`, and `home-manager`, plus the official `.nixmac` modules and a local `modules/darwin` tree.

## My Team
Nothing configured here yet.

## Packages
Packages come from three places: a small system profile, a larger Home Manager toolkit for the user, and Homebrew for GUI apps.

### System packages

Installed globally in `modules/darwin/packages.nix` (plus `vim` from the flake itself):

- `vim` — editor
- `nixfmt-rfc-style` — the RFC 166 Nix formatter, also wired up as `nix fmt`
- `gh` — GitHub CLI

### User (Home Manager) toolkit

Installed for `dz0ny` via `modules/home/shell-environment.nix`, either as bare packages or through dedicated program modules that also drop in config:

- Search/find: `ripgrep` (`rg`), `fd`, `fzf`, `bat`, `eza`
- Data: `jq`, `yq-go` (`yq`)
- Navigation/monitoring: `zoxide` (`z`/`zi`), `htop`
- Git: `git` with `delta` and `git-lfs`, plus `lazygit`
- Dev environments: `devenv`
- AI: `aider-chat`

### Homebrew

Homebrew is enabled through nix-darwin and reads its tap/brew/cask list from `.nixmac/homebrew/data.json`. It is deliberately non-destructive: `onActivation.cleanup = "none"` means apps you install by hand with `brew` are never removed, but on every rebuild it runs `autoUpdate` and `upgrade` to keep managed formulae and casks current. Notable casks referenced across the config include Ghostty, Tailscale, Setapp, Zoom, Privileges, OrbStack, Proton Drive, and Google/Chrome casks; `mise` and `gh`'s credential-helper binary also live under `/opt/homebrew`.

## Fonts
One programming font is installed system-wide so the terminal renders powerline and file-tree glyphs.

- `nerd-fonts.jetbrains-mono` — JetBrainsMono Nerd Font, the font Ghostty is configured to use; its bundled glyphs are what make the starship prompt, `eza` icons, and lazygit render correctly.

Note the packaging gotcha recorded in `fonts.nix`: on nixpkgs-unstable Nerd Fonts live under `nerd-fonts.*`, not the old `nerdfonts.override` form.

## macOS Settings
A large block of `system.defaults` in `macos-settings.nix` reproduces this machine's non-default preferences so a replacement Mac comes up identically after one rebuild — only keys that differ from Apple's factory defaults are recorded.

### Input & interaction

- Natural scrolling **off**; fast pointer (`mouse.scaling = 3.0`) and scroll-wheel speed.
- Snappy keyboard: `InitialKeyRepeat = 10`, `KeyRepeat = 1`, and press-and-hold accents disabled so holding a key repeats.
- Trackpad Force Click on with the lightest thresholds; Magic Mouse in one-button mode.
- ISO "tilde" key remapped to its expected position (`nonUS.remapTilde`).
- Keyboard layouts: **Croatian-PC** (primary) and Slovenian — a re-login may be needed before a freshly built Mac shows the active layout.
- Text replacements: `◊` → `@` and `omw` → `On my way!`.

### Dock, Finder & windows

- Dock is **always visible** (autohide off), on the **left** edge, tile size 78, no recents. The pinned apps, left to right, are Arc, Mail, ChatGPT, Slack, Zed, Claude, Ghostty, Tailscale — anything else is cleared from the Dock on rebuild.
- Bottom-right hot corner disabled so Quick Note never fires.
- Finder: list view, path bar shown, full POSIX path in title, hidden files shown, folders sorted first, new windows open in Home, and no disk icons on a clean desktop. Default search scope is the current folder.
- Window and Finder animations are turned off for a snappy feel; screenshots have no drop shadow but highlight clicks and capture HDR.

### Security posture (Pareto Security)

- Password required **immediately** on sleep/screensaver.
- AirDrop limited to **Contacts Only**; `.DS_Store` files kept off network/USB shares.
- Automatic updates fully on: macOS, security/critical data, config data, and App Store (`commerce.AutoUpdate`).
- The Mac never sleeps on idle (`power.sleep.computer = "never"`, mirroring `pmset -a sleep 0`), though displays/disks may still spin down.

Spotlight result categories are all disabled here (and Spotlight itself is disabled in Services). Some of these preferences have no typed nix-darwin option and are written verbatim through `CustomSystemPreferences` / `CustomUserPreferences`.

## Services
This machine runs very few background jobs by design; most launchd items belong to installed apps, not to this config.

- **Spotlight & Time Machine are disabled** on every activation via an activation script (`mdutil -a -i off -d`, `tmutil stopbackup`/`disable`). The commands are idempotent.
- **Weekly Nix garbage collection** runs as a root LaunchDaemon (`org.nix-darwin.nix-gc`) every **Sunday at 03:00**, deleting generations older than 30 days. Because Determinate Nix disables nix-darwin's `nix.gc`, this is a hand-written daemon; missed runs fire shortly after the Mac next wakes. Logs go to `/tmp/nix-gc.out.log` and `/tmp/nix-gc.err.log`.
- The **application firewall** is enabled with stealth mode on, but does **not** block all incoming — signed apps like LocalSend and Tailscale keep working (`modules/darwin/networking.nix`).

An audit note in `services.nix` records that no hand-authored launchd jobs exist; Setapp, Google Keystone, Zoom, Privileges, OrbStack, Proton Drive, Tailscale, and Determinate all manage their own plists and reappear once their casks are installed.

## Shell & Environment
The interactive shell is a fully declarative zsh set up for coding, themed to match Ghostty in Catppuccin Mocha.

### zsh & prompt

- zsh with autosuggestions, syntax highlighting, completion, and a 50 000-line shared history that ignores dups and space-prefixed commands.
- **starship** prompt: a two-line Catppuccin-Mocha powerline showing OS, directory, git branch/status, nix-shell, and command duration. It's built with a custom override that drops the `notify` feature, which otherwise crashes the Darwin linker.
- Shell bootstrap preserves `bun` (`~/.bun`) and `mise` activation. `mise` is installed via Homebrew and pins `flutter = "latest"` in `~/.config/mise/config.toml`; run `mise install` on a fresh Mac.

### Key tools & aliases

- **fzf** history is rebound from Ctrl-R to **Alt-R** (`⌥R`, emitted cleanly by Ghostty); Ctrl-R falls back to zsh's native reverse search. `Ctrl-T` finds files, `Alt-C` changes directory. `fd` backs all three so hidden files are found and `.gitignore` respected.
- `ls`/`ll`/`la`/`lt` are provided by **eza** (with git status and icons); `bat` replaces `cat`; `zoxide` gives `z`/`zi`; `lg` is aliased to **lazygit**.

### Ghostty terminal

`~/.config/ghostty/config` is managed here (the app itself is a Homebrew cask): JetBrainsMono Nerd Font at size 16, a translucent blurred black background (opacity 0.85), native macOS titlebar, and `copy-on-select`. Keybindings: `⌘⌥←`/`⌘⌥→` switch tabs, `⌘⇧D` splits right, and `⌘[`/`⌘]` move between splits.

### git

Configured in Home Manager with SSH commit signing available (`~/.ssh/id_ed25519.pub`, though `signByDefault = false`), `delta` as the diff pager, and git-lfs. Handy aliases: `git pp` (`push --force-with-lease`), `git up` (`pull origin main`), `git co` (`checkout main`). GitHub auth uses `gh` as the credential helper by absolute path (`/opt/homebrew/bin/gh`), which is why `gh` stays on Homebrew.

Home Manager backs up any pre-existing hand-written dotfile to `<file>.hm-backup` on first activation rather than overwriting it.

## AI Agents
Two coding-agent stacks are set up: a fully local Ollama+Aider path and a configured Claude Code, both managed through Home Manager in `modules/home/ai-agents.nix`.

### Local model (Ollama + Aider)

- `services.ollama` runs bound to `127.0.0.1:11434` (localhost only). `aider-chat` is the edit-capable harness.
- A per-user launchd agent (`dev.dz0ny.ollama-models`) waits for Ollama at login and pulls `qwen2.5-coder:7b`; the pull is idempotent, so it's safe on every login.

### Claude Code

- Installed via `programs.claude-code` (the one declared unfree package, allow-listed in `nix-overlays.nix`), with default permission mode `auto`, `medium` effort, fullscreen TUI, and both Sonnet/Haiku slots mapped to `claude-sonnet-4-6[1m]`.
- A **PreToolUse** hook rewrites every Bash call through `rtk`, the token-killing CLI proxy that filters and compresses command output. `rtk` is installed as a Home Manager package (in `ai-agents.nix`), but the hook invokes it by absolute Nix store path (`${pkgs.rtk}/bin/rtk hook claude`) so it still fires even when the menu-bar app's minimal PATH lacks the Home Manager profile.
- A **Stop** hook plays a random Warcraft peon sound (`.ogg` files vendored at build time, so no network access) via `afplay` when Claude is waiting for you.
- A set of official plugins is enabled (frontend-design, context7, feature-dev, commit-commands, code-simplifier, several LSPs, cloudflare) plus `devenv` and the `hakuto` marketplace from `teamniteo/hakuto`. `@RTK.md` is injected as context.

### Shared MCP servers

Defined once in `programs.mcp` and consumed by agents via `enableMcpIntegration`:

- **context7** — library/framework docs
- **cloudflare-docs** — Cloudflare platform docs
- **nixos** — nixpkgs / nix-darwin / Home Manager lookup, run via `nix run github:utensils/mcp-nixos`

## Security & Secrets
Authentication is convenience-first but hardened, and secrets are handled through sops-nix rather than being committed.

### Authentication

- **Touch ID for sudo** is enabled (`sudo_local.touchIdAuth`), including for `darwin-rebuild`.
- **Apple Watch** can also authorize sudo (`watchIdAuth`) — useful when the lid is closed — provided "Use your Apple Watch to unlock" is on in System Settings.
- There's an SSH Full Disk Access guard (`.nixmac/ssh-fda`): a preActivation check warns when you run over SSH without FDA, since `darwin-rebuild` can fail updating apps that way. It's a warning by default; enable `strict` in its `data.json` to abort instead.

### SSH client

`~/.ssh/config` is fully managed (the old file is backed up on first run). It's modern and hardened:

- Post-quantum-forward KEX, ChaCha20/AES-GCM ciphers, ETM MACs, ed25519-first key algorithms, hashed known-hosts, agent never forwarded, and connection multiplexing over `~/.ssh/sockets` (created by an activation step).
- Host aliases carry **Tags** (`work`/`personal`) and `Match tagged` blocks pick the identity per realm; today both realms reuse `~/.ssh/id_ed25519`. Aliases include `rpi`, `gh`/`github.com`, `air` (work), and a self-contained `linux-builder`. OrbStack and Colima includes are re-emitted at the top of the file. Key passphrases load from the macOS Keychain (`UseKeychain`).
- `~/.config/git/allowed_signers` is written so git can locally verify your own SSH-signed commits.

### Secrets (sops-nix)

- The base is wired up in `sops.nix`: YAML format, with the age key discovered from `$SOPS_AGE_KEY_FILE`, then `~/Library/Application Support/sops/age/keys.txt`, then `~/.config/sops/age/keys.txt` — the first that exists wins, otherwise no key.
- `sops-secrets.nix` is the place to declare actual secrets and bind their **file paths** into `environment.variables`; right now it holds only the example templates, so no secrets are defined yet.
