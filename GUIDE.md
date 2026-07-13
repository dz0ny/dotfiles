## Overview

This is a **nix-darwin + Home Manager** configuration for a single-owner Apple-silicon Mac (the host it was captured from is `Janezs-Mac-mini`), belonging to `dz0ny` (Janez T, `hey@dz0ny.dev`). It is built from the `nixmac` template (v0.1.3) and mixes three layers: declarative **nix-darwin** modules for macOS system settings, fonts, and platform plumbing; a **Home Manager** module that owns the daily-coding terminal and its dotfiles; and a **Homebrew** manifest (`.nixmac/homebrew/data.json`) that carries all the GUI apps and a few CLI tools Nix doesn't manage.

The split is deliberate and worth internalizing: **GUI apps and their background helpers come from Homebrew casks**, the **shell/CLI toolchain comes from Home Manager**, and **macOS preferences come from nix-darwin**. The machine looks tailored to a **mobile/app developer** — Flutter, Android platform tools, CocoaPods, Fastlane, plus a broad set of communication, AI, and 3D-printing/CAD apps. Rebuilds are applied with `darwin-rebuild switch --flake .#<hostname>`, and `nixfmt-rfc-style` is wired up as `nix fmt` for formatting the config itself. Touch ID works for `sudo` (including the rebuild), so most privileged operations just ask for a fingerprint.

## Packages

Packages come from three places.

### System profile (nix-darwin)

`environment.systemPackages` is intentionally almost empty — it holds only:

- `nixfmt-rfc-style` — the official RFC 166 Nix formatter, also exposed as `nix fmt`.

### Home Manager CLI toolkit

The real command-line toolbox lives in `modules/home/dz0ny.nix` and is the single source of truth for these tools (several were deliberately migrated off Homebrew). Some are plain packages, most are configured `programs.*` modules:

- **Search / files:** `ripgrep` (`rg`), `fd`, `fzf`, `bat`, `eza`, `zoxide`
- **Data:** `jq`, `yq-go` (`yq`)
- **System:** `htop`
- **Git:** `lazygit` (aliased `lg`), plus a fully configured `git`
- **Dev environments:** `devenv` (`devenv shell` / `devenv up`)
- **Prompt:** `starship`

Day-to-day niceties you inherit:

- `fzf` bindings: **Ctrl-R** history search, **Ctrl-T** file picker, **Alt-C** cd. All three walk the tree with `fd` (hidden files included, `.git` excluded).
- `eza` provides the `ls` / `ll` / `la` / `lt` aliases (it overrides any hand-rolled `ll`), with git status and icons on.
- `zoxide` gives you `z` / `zi` for jump-to-directory.
- `bat` is themed Catppuccin Mocha to match the terminal.

> **Gotcha:** `starship` is built with a custom override that disables its default features and keeps only `battery`. Don't "fix" this — the default `notify` feature pulls in a Darwin link step that crashes the linker and breaks the whole system build. Desktop notifications aren't used here.

### Homebrew (`brew`)

CLI tools kept on Homebrew rather than Nix: `adb-enhanced`, `cocoapods`, `fastlane`, `gh`, `heroku`, `mole`, `rtk`.

> **Why `gh` stays on brew:** the git credential helper references `/opt/homebrew/bin/gh` by absolute path, so GitHub HTTPS auth depends on the Homebrew install being present.

`mise` and `bun` are **not** in any manifest here — they're bootstrapped from `~/.local/bin/mise` and `~/.bun` in the shell init (see Shell & Environment).

### Homebrew casks (GUI apps)

A large set installed as casks. Grouped roughly:

- **Browsers:** `arc`, `brave-browser`, `google-chrome`
- **Terminal / editors / dev:** `ghostty`, `zed`, `tableplus`, `gitup`, `orbstack`, `utm`, `setapp`
- **AI:** `chatgpt`, `claude`, `codex`
- **Mobile / hardware dev:** `flutter`, `android-platform-tools`, `androidtool`, `insta360-link-controller`
- **3D / CAD / making:** `bambu-studio`, `shapr3d`
- **Comms:** `slack`, `signal`, `whatsapp`, `zoom`, `proton-mail`, `localsend`
- **Remote access / networking:** `tailscale`, `rustdesk`, `teamviewer`
- **Security / utilities:** `proton-pass`, `pareto-security`, `privileges`, `appcleaner`, `raycast`, `stats`, `spotify`

Many casks (`nikitabobko/tap` for aerospace-style tooling, `charmbracelet/tap`, `stripe/stripe-cli`, `daytonaio/cli`, `netbirdio/tap`, `deskflow/tap`, `dotenvx/brew`, `tinygo-org/tools`, and more) are enabled via the `taps` list, so their formulae are resolvable.

## Fonts

One font is installed declaratively through nix-darwin (`fonts.packages`):

- **`nerd-fonts.jetbrains-mono`** — the programming font used by Ghostty, and the Nerd Font variant is required for the glyphs in `lazygit`, `eza` icons, and the `starship` prompt symbols.

Note the namespacing: on nixpkgs-unstable Nerd Fonts live under `nerd-fonts.*` (the old `nerdfonts.override` API was removed). After font changes, macOS may need its font cache rebuilt. Everything downstream (Ghostty's `font-family = JetBrainsMono Nerd Font`, `lazygit`'s `nerdFontsVersion = "3"`, `eza` icons) assumes this font is present.

## macOS Settings

macOS preferences are captured in `modules/darwin/system-defaults.nix` — only keys that differ from Apple's factory defaults are recorded, so a replacement Mac reproduces this exact feel on first `darwin-rebuild switch`. (The `defaults.nix`, `environment.nix`, and `networking.nix` modules are template stubs with everything commented out — nothing active there.)

### Keyboard & input

- **Snappy key repeat:** `InitialKeyRepeat = 10`, `KeyRepeat = 1` (fastest), and press-and-hold accents disabled (`ApplePressAndHoldEnabled = false`) so holding a key repeats it.
- **Full keyboard access** (`AppleKeyboardUIMode = 3`): Tab moves focus to every control.
- ISO "tilde" key remapped to its expected position (`system.keyboard.nonUS.remapTilde`).
- **Input sources:** Croatian-PC (primary/selected) plus Slovenian, with the character palette and press-and-hold helpers. *A newly-built Mac may need a re-login before the active layout shows.*
- **Text replacements:** `◊` → `@`, and `omw` → `On my way!`.

### Trackpad, mouse & scrolling

- Natural scrolling **off**; Force Click **on** with the lightest click thresholds.
- Three-finger tap gesture enabled (look up / data detectors).
- Fast pointer and scroll-wheel tracking (`com.apple.mouse.scaling = 3.0`, `com.apple.scrollwheel.scaling = 1.7`).
- Magic Mouse in one-button mode.

### Dock

- Lives on the **left edge**, **always visible** (autohide off), `tilesize = 78`, no recent apps, minimize-into-app-icon.
- Bottom-right hot corner disabled (no accidental Quick Note).
- **Pinned apps** are managed exactly (anything not listed is cleared on rebuild), left-to-right: **Arc, Mail, ChatGPT, Slack, Zed, Claude, Ghostty, Tailscale**.

### Finder

- **List view** default (`Nlsv`), folders sorted first, path bar shown, POSIX path in the title bar.
- New windows open in **Home (`~`)**; search defaults to the **current folder** (`SCcf`).
- **Hidden dotfiles shown** (`AppleShowAllFiles`), all extensions shown, no extension-change warning.
- Clean desktop: no internal/external/removable disk icons.
- Finder animations disabled; no `.DS_Store` on network shares or USB volumes.

### Windows, display & screenshots

- Window animations effectively instant (`NSAutomaticWindowAnimationsEnabled = false`, `NSWindowResizeTime = 0.001`); `WindowManager` set to auto-hide and hide the desktop, with app-window grouping on.
- Scrollbars always shown; save/print panels expanded by default.
- Menu-bar clock shows day-of-week, date, and AM/PM.
- Screenshots: no window shadow, clicks highlighted, HDR captured.
- Screen lock requires the password **10 seconds** after sleep/screensaver.

## Services

**Nothing is declared in Nix here** — but that's by design, not by omission, so it's worth knowing why.

The `services` block, `launchd.daemons`, and `launchd.user.agents` in `modules/darwin/services.nix` are all commented-out examples. A full audit of the live machine (captured 2026-07-11) found **no hand-authored launchd jobs**. Every non-Apple background service belongs to an app that installs and manages its own `launchd` plist, and each reappears automatically once the corresponding Homebrew cask is installed:

- **Setapp** — `com.setapp.DesktopClient.*`
- **Google Keystone** (updater) — `com.google.keystone.*`
- **Zoom** — `us.zoom.*`
- **Privileges** — `corp.sap.privileges.*`
- **OrbStack** — `dev.orbstack.*`
- **Proton Drive** — `ch.protonmail.drive.*`
- **Tailscale** — `io.tailscale.ipn.*`
- **Determinate Nix** — `systems.determinate.*` / `org.nixos.activate-system`

Login items (Pareto Security, Stats, Raycast, Android File Transfer Agent) are likewise registered by the apps themselves via `SMAppService`. So there is nothing to start or manage from this repo — installing the casks brings the services back. The audit can be refreshed with `scripts/capture-state.sh`.

## Shell & Environment

The interactive environment is **zsh**, owned end-to-end by Home Manager, which rewrites `~/.zshrc` (and other managed dotfiles). On first activation any pre-existing hand-written file is moved aside to `<file>.hm-backup` rather than clobbered.

### zsh

- Autosuggestions, syntax highlighting, and completion all enabled.
- Large shared history: 50,000 entries, dedup, ignore-space, shared across sessions.
- Alias `lg` → `lazygit`; `ls`-family aliases come from `eza`.

### Shell bootstrap (`initContent`)

Two toolchains are activated from outside Nix — this is the gotcha to remember, since they aren't in any package manifest:

- **bun:** `BUN_INSTALL="$HOME/.bun"` is put on `PATH` and `~/.bun/_bun` is sourced.
- **mise:** if `~/.local/bin/mise` exists, it's activated (`eval "$(mise activate zsh)"`). mise is installed via Homebrew and pins the global toolchain from `~/.config/mise/config.toml`, which this config writes as:

  ```toml
  [tools]
  flutter = "latest"
  ```

  So a fresh Mac gets Flutter (and a matching JDK) after `mise install`.

### Prompt (starship)

A two-line Catppuccin Mocha prompt: an info line (`directory`, `git_branch`, `git_status`, `nix_shell`, `cmd_duration`) then a `❯` caret (green on success, red on error). Directory truncates to the repo root; command durations show only above 2s. The zsh integration hook is injected automatically. Prompt glyphs rely on the JetBrainsMono Nerd Font.

### Terminal (Ghostty)

Ghostty.app comes from a Homebrew cask; only its config (`~/.config/ghostty/config`) is managed here:

- `theme = catppuccin-mocha`, `font-family = JetBrainsMono Nerd Font`, `font-size = 14`, thickened.
- Comfortable spacing/padding, non-blinking block cursor, hide cursor while typing.
- `macos-option-as-alt = true`, `copy-on-select = clipboard`, and `confirm-close-surface = false` (windows close without a prompt).

### Environment variables

`environment.variables` (system) and the sops runtime bindings are both empty template stubs — no custom `EDITOR`, `LANG`, etc. are exported at the system level. Nothing to configure to use the machine; the toolchain relies on `PATH` set up in the zsh init.

## Security & Secrets

### Touch ID for sudo

`security.pam.services.sudo_local.touchIdAuth = true` — you can authenticate `sudo` (including `darwin-rebuild`) with **Touch ID** instead of a password. This is on by default here.

### git commit signing (SSH)

Git is configured to sign with **SSH keys**, not GPG:

- Format `ssh`, signing key `~/.ssh/id_ed25519.pub`. Note `signByDefault = false` and `tag.gpgSign = false`, so commits are **not** force-signed unless you opt in per commit.
- Local verification works via `~/.config/git/allowed_signers`, which this config writes with the personal ed25519 public key for `hey@dz0ny.dev` — so `git log --show-signature` can verify your own commits.
- GitHub auth uses `gh` as the credential helper by absolute path (`/opt/homebrew/bin/gh auth git-credential`), which is why `gh` must stay installed via Homebrew.

Useful git aliases: `pp` (`push --force-with-lease`), `up` (`pull origin main`), `co` (`checkout main`). Sensible defaults are set throughout — `pull.rebase`, `push.autoSetupRemote`, `fetch.prune`, `rerere`, histogram diffs, and `help.autocorrect = prompt`.

### Hardened SSH client (`~/.ssh/config`)

Home Manager owns `~/.ssh/config` (previous file backed up on first activation). Key points for daily use:

- **Global defaults (`Host *`):** modern post-quantum-forward KEX/ciphers/MACs, keys added to the agent on first use, passphrases loaded from the **macOS Keychain**, agent forwarding off, hashed known_hosts, `StrictHostKeyChecking = ask`, and connection multiplexing (`ControlMaster auto`, sockets under `~/.ssh/sockets/`, persisted 10m). An activation step creates `~/.ssh/sockets` (mode 700) since ssh won't.
- **Host aliases carry a realm `Tag`** — `Match tagged personal` / `Match tagged work` blocks then attach the identity. Both realms currently use `~/.ssh/id_ed25519` (a dedicated work key is a documented TODO).
  - Personal: `rpi` (rpi.local), `gh` / `github.com` (git@github.com).
  - Work: `air` (air.radioterminal.si).
- **`linux-builder`** — the Nix Linux remote builder on `localhost:31022` as user `builder`, with its own key `/etc/nix/builder_ed25519`.
- **Includes** at the very top pull in OrbStack (`~/.orbstack/ssh/config`, the `orb` host) and Colima (`~/.colima/ssh_config`) helper configs.

> You'll need the private key `~/.ssh/id_ed25519` present for any of the signing/SSH-host functionality to work; the config references it but does not provision it.

### sops-nix (secrets, staged but empty)

The `sops-nix` framework is wired up but **no secrets are declared yet** — `sops.secrets` and the runtime `environment.variables` bindings are empty templates. The age key is resolved at build time in this order:

1. `$SOPS_AGE_KEY_FILE` (if set and the path exists),
2. `~/Library/Application Support/sops/age/keys.txt`,
3. `~/.config/sops/age/keys.txt`,
4. otherwise `null`.

Default format is YAML. To start using secrets, drop your age key at one of those paths and add entries under `sops.secrets`. Note that **FileVault / full-disk encryption is managed by macOS**, not by this config.