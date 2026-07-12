#!/usr/bin/env bash
# One-shot, read-only capture of live macOS state for folding into the
# nix-darwin flake (defaults, Homebrew, shell tools, launchd items).
# Writes a single report to ./capture-state.out
set -uo pipefail
OUT="$(cd "$(dirname "$0")" && pwd)/capture-state.out"
exec > "$OUT" 2>&1

sec() { printf '\n\n========== %s ==========\n' "$1"; }

sec "SYSTEM"
sw_vers
echo "arch: $(uname -m)"
echo "LocalHostName: $(scutil --get LocalHostName 2>/dev/null)"
echo "ComputerName: $(scutil --get ComputerName 2>/dev/null)"

sec "BREW LEAVES (installed-on-request, i.e. things you asked for)"
brew leaves --installed-on-request 2>/dev/null

sec "BREW CASKS"
brew list --cask 2>/dev/null

sec "BREW TAPS"
brew tap 2>/dev/null

sec "BREW BUNDLE DUMP (--describe)"
brew bundle dump --file=- --describe 2>/dev/null

sec "USER LAUNCHAGENTS (~/Library/LaunchAgents)"
ls -1 "$HOME/Library/LaunchAgents" 2>/dev/null
for f in "$HOME"/Library/LaunchAgents/*.plist; do
  [ -e "$f" ] || continue
  echo "----- $f -----"
  /usr/libexec/PlistBuddy -c Print "$f" 2>/dev/null || cat "$f"
done

sec "SYSTEM LAUNCHDAEMONS (/Library/LaunchDaemons)"
ls -1 /Library/LaunchDaemons 2>/dev/null

sec "SYSTEM LAUNCHAGENTS (/Library/LaunchAgents)"
ls -1 /Library/LaunchAgents 2>/dev/null

sec "LAUNCHCTL user list (non-Apple)"
launchctl list 2>/dev/null | grep -v 'com\.apple' || true

sec "LOGIN ITEMS"
osascript -e 'tell application "System Events" to get the name of every login item' 2>/dev/null

sec "SHELL"
echo "SHELL=$SHELL"
dscl . -read "/Users/$USER" UserShell 2>/dev/null

sec "MISE / RUNTIME VERSIONS"
command -v mise >/dev/null 2>&1 && mise ls 2>/dev/null
[ -f "$HOME/.config/mise/config.toml" ] && { echo "--- ~/.config/mise/config.toml ---"; cat "$HOME/.config/mise/config.toml"; }
[ -f "$HOME/.tool-versions" ] && { echo "--- ~/.tool-versions ---"; cat "$HOME/.tool-versions"; }

sec "USER BIN DIRS"
for d in "$HOME/.local/bin" "$HOME/.bun/bin" "$HOME/go/bin" "$HOME/.cargo/bin"; do
  [ -d "$d" ] && { echo "--- $d ---"; ls -1 "$d"; }
done

sec "NSGlobalDomain (-g)"
defaults read -g 2>/dev/null

for dom in \
  com.apple.dock com.apple.finder com.apple.WindowManager \
  com.apple.controlcenter com.apple.menuextra.clock \
  com.apple.Safari com.apple.Terminal com.apple.screencapture \
  com.apple.screensaver com.apple.AppleMultitouchTrackpad \
  com.apple.driver.AppleBluetoothMultitouch.trackpad \
  com.apple.driver.AppleBluetoothMultitouch.mouse \
  com.apple.AppleMultitouchMouse com.apple.universalaccess \
  com.apple.spaces com.apple.HIToolbox com.apple.LaunchServices \
  com.apple.desktopservices com.apple.SoftwareUpdate \
  com.apple.commerce com.apple.TimeMachine com.apple.ActivityMonitor \
  com.apple.trackpad com.apple.menuextra.battery ; do
  sec "DOMAIN $dom"
  defaults read "$dom" 2>/dev/null
done

sec "DONE"
echo "capture complete"
