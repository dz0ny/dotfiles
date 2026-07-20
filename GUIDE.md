## Overview
This is a nix-darwin flake managing an Apple Silicon Mac mini (`Janezs-Mac-mini`) for a single user, `dz0ny`, with Home Manager wired in for the user-level dotfiles. It's tailored for a developer who lives in the terminal — Ghostty, zsh, git with SSH signing, devenv — and who cares about a locked-down, Pareto Security-shaped macOS posture.

Nix itself is managed by Determinate (`nix.enable = false`), so nix-darwin only handles the configuration, not the Nix installation. Rebuild with `darwin-rebuild switch --flake .#Janezs-Mac-mini`; format the Nix files with `nix fmt` (nixfmt-rfc-style).

## My Team
Nothing configured here yet.

## Packages
Packages arrive from three places — the system profile, Home Manager, and Homebrew — with a deliberate split between them.

### System profile (`modules/darwin/packages.nix`)

- `nixfmt-rfc-style` — the Nix formatter, also wired up as `nix fmt`
- `gh` — GitHub CLI
- `vim` — declared in `flake.nix` alongside the host settings
- `caddy` — pulled in by the dev-proxy module

### User profile (`modules/home/shell-environment.nix`)

The daily CLI toolkit lives here: `ripgrep`, `fd`, `jq`, `yq-go`, `htop`, and `devenv` as plain packages, plus program modules for `fzf`, `bat`, `eza`, `zoxide`, `lazygit`, `git` (with `delta` and `git-lfs`), `starship`, and `ssh`. Home Manager is the single source of truth for these — `ripgrep` and `git` were deliberately removed from Homebrew to avoid duplication.

### Homebrew

Homebrew is enabled and driven by `.nixmac/homebrew/data.json` (taps, brews, casks). Two things worth knowing:

- `onActivation.cleanup = "none"` — anything you install by hand with `brew` is left alone; nix-darwin only *ensures* the declared packages exist.
- `autoUpdate` and `upgrade` are both on, so every `darwin-rebuild switch` refreshes formulae and upgrades outdated casks. Expect switches to take a while.

`gh` stays on Homebrew as well because the git credential helper references `/opt/homebrew/bin/gh` by absolute path. `mise` is also a Homebrew install, activated from the zsh startup file.

## Fonts
One font is installed system-wide, and it's the one the terminal depends on.

`nerd-fonts.jetbrains-mono` is installed via `fonts.packages`. Ghostty is configured to use `JetBrainsMono Nerd Font`, and the Nerd Font glyphs are what make the starship powerline prompt, `eza --icons`, and lazygit render correctly — swap the font out and those all break visually. Note that on nixpkgs-unstable Nerd Fonts are namespaced under `nerd-fonts.*`; the old `nerdfonts.override` form is gone.

## macOS Settings
`modules/darwin/macos-settings.nix` reproduces every preference that differs from macOS factory defaults, so a replacement Mac comes up configured on the first switch.

### Input and keyboard

- Natural scrolling **off**; Force Click on, with both click thresholds at the lightest setting; Magic Mouse in one-button mode
- Fast keyboard: `InitialKeyRepeat = 10`, `KeyRepeat = 1`, press-and-hold accent popover disabled so holding a key repeats it
- Fast pointer: `com.apple.mouse.scaling = 3.0`, `com.apple.scrollwheel.scaling = 1.7`
- Full keyboard access (`AppleKeyboardUIMode = 3`) so Tab reaches every control
- Input sources are Croatian-PC (selected) plus the character palette and press-and-hold helpers; **a newly built Mac may need a re-login before the layout takes effect**
- The non-US tilde key is remapped via `system.keyboard.nonUS.remapTilde`
- Text replacements: `◊` → `@` and `omw` → `On my way!`

### Finder and Dock

- Finder: list view, path bar shown, folders first, new windows open in Home, hidden files shown, full POSIX path in the title, search scoped to the current folder, no disks on the desktop, extension-change warning off
- Dock: always visible on the **left** edge, 78px tiles, no recents, minimize into app icon, bottom-right hot corner disabled (no accidental Quick Note)
- Pinned Dock apps, in order: Arc, Mail, ChatGPT, Slack, Zed, Claude, Ghostty, Tailscale. **Anything not in that list is cleared from the Dock on every rebuild.**
- Stage Manager/window settings: window grouping on, auto-hide on, desktop hidden, tiled window margins off

### Speed and appearance

Window and Finder animations are disabled (`NSAutomaticWindowAnimationsEnabled = false`, `NSWindowResizeTime = 0.001`, `DisableAllAnimations`), scrollbars are always shown, and save/print panels open expanded. Screenshots drop the window shadow, highlight clicks, and capture HDR. `.DS_Store` files are kept off network shares and USB volumes.

### Security posture

- Screensaver/sleep requires the password **immediately** (`askForPasswordDelay = 0`)
- Gatekeeper quarantine (`LSQuarantine`) stays on
- AirDrop discovery limited to Contacts Only
- Automatic macOS updates install themselves; `com.apple.SoftwareUpdate` check/download/config-data/critical-update keys and `com.apple.commerce.AutoUpdate` are all enabled via `CustomSystemPreferences`
- `power.sleep.computer = "never"` — the machine never idle-sleeps (displays and disks still spin down)

## Services
Two custom LaunchDaemons run as root, plus two activation-time scripts that turn off macOS background facilities.

### Dev proxy (`modules/darwin/dev-proxy.nix`)

A Caddy reverse proxy runs as a root LaunchDaemon (`org.nix-darwin.dev-proxy`) so it can bind port 80, mapping friendly names to local dev servers:

- `http://app.localhost` → `127.0.0.1:3000`
- `http://api.localhost` → `127.0.0.1:8080`

macOS resolves `*.localhost` to 127.0.0.1 on its own, so there's no `/etc/hosts` or dnsmasq involved — add a name/port pair to the `routes` attrset and rebuild. **These are plain `http://` on purpose**: automatic HTTPS would mint certs from Caddy's internal CA and try to install it into the login keychain, which requires an interactive prompt. Caddy state lives in `/var/lib/dev-proxy`, and logs go to `/tmp/dev-proxy.out.log` and `/tmp/dev-proxy.err.log`.

### Weekly garbage collection

Because Determinate Nix means `nix.gc` is unavailable, a LaunchDaemon (`org.nix-darwin.nix-gc`) runs `nix-collect-garbage --delete-older-than 30d` every Sunday at 03:00. `StartCalendarInterval` fires missed runs after the Mac next wakes, so a sleeping machine still gets collected. Logs: `/tmp/nix-gc.out.log`, `/tmp/nix-gc.err.log`.

### Spotlight and Time Machine

Every activation runs `mdutil -a -i off`, `mdutil -a -d`, `tmutil stopbackup`, and `tmutil disable`. Spotlight indexing and all Spotlight activity are off system-wide, matching the `com.apple.Spotlight` preference that hides every result category. Time Machine automatic backups are disabled. Both are idempotent, so they re-assert on every switch.

### Not managed here

An audit of the live machine (captured 2026-07-11) found no hand-authored launchd jobs. Setapp, Google Keystone, Zoom, Privileges, OrbStack, Proton Drive, Tailscale, and Determinate Nix all install and manage their own plists, and login items (Pareto Security, Stats, Raycast, Android File Transfer) register themselves via SMAppService — they reappear once the corresponding Homebrew casks are installed.

## Shell & Environment
The interactive terminal is fully declarative: Ghostty as the emulator, zsh as the shell, starship as the prompt, and a matched Catppuccin Mocha theme across the tools.

### Ghostty

`~/.config/ghostty/config` is managed here (the app itself is a Homebrew cask). Key points:

- JetBrainsMono Nerd Font at 16pt, thickened, with 12px padding and a block non-blinking cursor
- Translucent black background (`background-opacity = 0.85`, `background-blur = 16`), native macOS titlebar
- `copy-on-select = clipboard`, `confirm-close-surface = false`, `macos-option-as-alt = true`
- `⌘⌥←` / `⌘⌥→` are rebound to previous/next tab (browser-style); splits remain on `⌘[` / `⌘]`

### zsh and keybindings

Autosuggestions, syntax highlighting, and completion are on, with 50k shared history that ignores dups and space-prefixed commands. The one gotcha worth memorizing:

- **`⌥R` opens fzf history**, not `Ctrl-R`. Ctrl-R is unreliable across terminals and multiplexers, so it was handed back to zsh's native incremental reverse-search.
- `Ctrl-T` is fzf file search and `⌥C` is fzf cd, both walking with `fd` so hidden files are included and `.gitignore` is respected.

`ls`/`ll`/`la`/`lt` come from eza (with git status and icons), `z`/`zi` from zoxide, `lg` is aliased to lazygit, and `bat` replaces `cat` with highlighting. Bun (`~/.bun/bin`) and mise (`~/.local/bin/mise activate zsh`) are bootstrapped at shell startup.

### Prompt

Starship renders a two-line Catppuccin Mocha powerline: OS icon, directory, git branch/status, nix shell, and command duration (shown past 2s), then the `❯` caret. Note that starship is built with `--no-default-features` plus only `battery` — the default `notify` feature pulls in `mac-notification-sys`, whose link step crashes the cctools linker on this toolchain and breaks the whole system build.

### git

Configured as `Janez T <hey@dz0ny.dev>` with delta as the pager (`n`/`N` to navigate hunks) and git-lfs enabled. Behavior worth knowing: `pull.rebase`, `push.autoSetupRemote`, `push.followTags`, `fetch.prune`/`pruneTags`/`all`, `rebase.autoStash`/`autoSquash`/`updateRefs`, histogram diffs, `rerere` on, and `help.autocorrect = "prompt"`. Aliases: `pp` (`push --force-with-lease`), `up` (`pull origin main`), `co` (`checkout main`).

### SSH

`~/.ssh/config` is Home Manager-owned and uses tag-based identity routing. Host aliases `rpi`, `gh`, and `github.com` carry `Tag personal`; `air` (air.radioterminal.si) carries `Tag work`; both currently resolve to `~/.ssh/id_ed25519` via `Match tagged` blocks. `linux-builder` is self-contained on port 31022 with its own `/etc/nix/builder_ed25519` key.

- Global defaults: `AddKeysToAgent yes`, `UseKeychain`, `ForwardAgent no`, hashed known_hosts, `StrictHostKeyChecking ask`, and a modern post-quantum-forward cipher/KEX set
- Connection multiplexing via `~/.ssh/sockets/%C` with a 10m persist; the socket directory is created by a Home Manager activation step
- OrbStack (`~/.orbstack/ssh/config`) and Colima (`~/.colima/ssh_config`) are pulled in with an `Include` at the very top of the file, which is where OrbStack requires it

### mise

`~/.config/mise/config.toml` pins `flutter = "latest"` globally (which pulls in a matching JDK). On a fresh Mac, run `mise install` to materialize it.

### System environment variables

`environment.variables` is currently empty — nothing is exported system-wide.

## AI Agents
Two agent setups coexist: Claude Code as the primary harness, and a fully local Ollama + Aider pair for offline work.

### Claude Code

`programs.claude-code` manages the configuration. Both the default Haiku and Sonnet model slots point at `claude-sonnet-4-6[1m]`, permissions default to `auto`, effort level is `medium`, and the TUI runs fullscreen. A `PreToolUse` hook on `Bash` invokes `rtk hook claude`, and `@RTK.md` is injected as context.

A `Stop` hook plays a random Warcraft peon voice line whenever Claude finishes and is waiting for input: it runs `afplay` against a randomly picked `.ogg` from a `peonSounds` derivation. Those sounds are fetched at build time with `fetchFromGitHub` from `zupo/dotfiles` (pinned to rev `63c622b`) and installed into the Nix store, so the hook never touches the network at runtime.

Enabled plugins include `frontend-design`, `context7`, `feature-dev`, `commit-commands`, `code-simplifier`, `cloudflare`, the `gopls`/`swift`/`clangd` LSP plugins, `devenv@devenv-claude`, and `hakuto` from the `teamniteo/hakuto` GitHub marketplace. Claude Code is the one unfree package on this system — `nix-overlays.nix` scopes `allowUnfreePredicate` to exactly `claude-code` rather than flipping `allowUnfree` globally.

### MCP servers

`programs.mcp` defines a shared baseline that Claude Code consumes via `enableMcpIntegration`:

- `context7` — current library and framework docs (`https://mcp.context7.com/mcp`)
- `cloudflare-docs` — Cloudflare platform docs (`https://docs.mcp.cloudflare.com/mcp`)
- `nixos` — nixpkgs/nix-darwin/Home Manager option lookup, run via `nix run github:utensils/mcp-nixos`

### Local models

`services.ollama` runs bound to `127.0.0.1:11434` — localhost only, nothing exposed. A user LaunchAgent (`dev.dz0ny.ollama-models`) waits up to 60 seconds for the service at login, then pulls `qwen2.5-coder:7b`; pulls are idempotent so this is safe to re-run. `aider-chat` is installed as the edit-capable harness on top.

## Security & Secrets
Authentication is biometric where possible, secrets go through sops-nix with an age key, and the firewall stays on.

### Authentication

Both `security.pam.services.sudo_local.touchIdAuth` and `watchIdAuth` are enabled, so `sudo` (including `darwin-rebuild`) accepts Touch ID or an Apple Watch tap. Apple Watch authorization additionally requires "Use your Apple Watch to unlock apps and your Mac" to be on in System Settings.

### Firewall

The macOS application firewall is enabled with stealth mode on, so the Mac doesn't answer unsolicited probes. `blockAllIncoming` is deliberately **off** — blocking everything would break LocalSend, Tailscale, and other local services.

### Secrets

sops-nix is wired in with YAML as the default format. The age key is discovered in order:

1. `$SOPS_AGE_KEY_FILE`, if set and the file exists
2. `~/Library/Application Support/sops/age/keys.txt`
3. `~/.config/sops/age/keys.txt`

If none exist, `sops.age.keyFile` is `null`. `modules/darwin/sops-secrets.nix` is where secret declarations and their runtime bindings go — it currently holds only commented examples showing the expected shape (`sopsFile`, `path` under `/run/secrets/`, owner `dz0ny`, group `staff`, mode `0400`). The convention is to export secret *file paths* through `environment.variables`, never values.

### SSH Full Disk Access check

The `.nixmac/ssh-fda` module adds a pre-activation check: if you run `darwin-rebuild` over SSH without Full Disk Access, it warns that app updates may fail and points you at System Settings → General → Sharing → Remote Login → "Allow full disk access for remote users." It's a warning by default, not fatal — `strict` mode (which aborts) is off unless enabled in that module's `data.json`.

### Commit signing

Git is set up for SSH commit signing with `~/.ssh/id_ed25519.pub`, but `signByDefault = false` and `tag.gpgSign = false`, so signing is opt-in per commit. `~/.config/git/allowed_signers` is generated with the personal ed25519 public key so `git log --show-signature` can verify locally-signed commits.
