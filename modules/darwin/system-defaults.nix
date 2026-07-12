{
  # macOS system defaults managed by nixmac.
  #
  # These mirror the non-default preferences captured from the live machine so a
  # replacement Mac reproduces them on first `darwin-rebuild switch`. Only keys
  # that differ from the macOS factory default are recorded here.

  system.defaults.NSGlobalDomain = {
    # Natural scrolling off.
    "com.apple.swipescrolldirection" = false;
    # Force Click / haptic feedback enabled on the trackpad.
    "com.apple.trackpad.forceClick" = true;
    AppleShowAllExtensions = true;
    InitialKeyRepeat = 15;
    KeyRepeat = 2;
    # Spring-loaded folders enabled with a 0.5s hover delay.
    "com.apple.springing.enabled" = true;
    "com.apple.springing.delay" = 0.5;
  };
  system.defaults.WindowManager = {
    AppWindowGroupingBehavior = true;
    AutoHide = true;
    EnableTiledWindowMargins = false;
    HideDesktop = true;
  };
  system.defaults.dock = {
    # Dock stays visible (autohide off) and lives on the left edge.
    autohide = false;
    minimize-to-application = true;
    orientation = "left";
    show-recents = false;
    tilesize = 78;
    # Bottom-right hot corner disabled (1 = no action) so the default
    # Quick Note trigger doesn't fire.
    wvous-br-corner = 1;
    # Pinned Dock apps, left-to-right, exactly as arranged on the live machine.
    # Anything not in this list is cleared from the Dock on rebuild.
    persistent-apps = [
      "/Applications/Arc.app"
      "/System/Applications/Mail.app"
      "/Applications/ChatGPT.app"
      "/Applications/Slack.app"
      "/Applications/Zed.app"
      "/Applications/Claude.app"
      "/Applications/Ghostty.app"
      "/Applications/Tailscale.app"
    ];
  };
  system.defaults.finder = {
    FXEnableExtensionChangeWarning = false;
    FXPreferredViewStyle = "Nlsv";
    ShowPathbar = true;
    ShowStatusBar = false;
    _FXSortFoldersFirst = true;
    _FXSortFoldersFirstOnDesktop = true;
    # New Finder windows open in Home (~) instead of Recents.
    NewWindowTarget = "Home";
    # Keep the desktop clean: no internal/external disk or removable-media icons.
    ShowHardDrivesOnDesktop = false;
    ShowExternalHardDrivesOnDesktop = false;
    ShowRemovableMediaOnDesktop = false;
  };
  system.defaults.magicmouse = {
    MouseButtonMode = "OneButton";
  };
  system.defaults.menuExtraClock = {
    ShowAMPM = true;
    ShowDate = 1;
    ShowDayOfWeek = true;
  };
  system.defaults.trackpad = {
    TrackpadThreeFingerTapGesture = 2;
  };

  # ---------------------------------------------------------------------------
  # Settings without a typed nix-darwin option, written verbatim to their
  # domains. These still differ from the macOS factory defaults.
  # ---------------------------------------------------------------------------
  system.defaults.CustomUserPreferences = {
    NSGlobalDomain = {
      # Double-clicking a window title bar does nothing (default is zoom/minimize).
      AppleMiniaturizeOnDoubleClick = false;
      # Pointer + scroll-wheel tracking speed (fast — both above default).
      "com.apple.mouse.scaling" = 3.0;
      "com.apple.scrollwheel.scaling" = 1.7;
      # Text replacements from System Settings → Keyboard → Text Input.
      NSUserDictionaryReplacementItems = [
        {
          on = 1;
          replace = "◊";
          "with" = "@";
        }
        {
          on = 1;
          replace = "omw";
          "with" = "On my way!";
        }
      ];
    };

    # Don't scatter .DS_Store files onto network shares or USB volumes.
    "com.apple.desktopservices" = {
      DSDontWriteNetworkStores = true;
      DSDontWriteUSBStores = true;
    };

    # Screenshots/recordings highlight clicks and capture HDR.
    "com.apple.screencapture" = {
      showsClicks = true;
      captureHDR = true;
    };

    # Keyboard input sources: Croatian-PC (primary) + Slovenian, plus the
    # character palette and press-and-hold helpers. macOS may require a
    # re-login before a newly-built Mac reflects the active layout.
    "com.apple.HIToolbox" = {
      AppleEnabledInputSources = [
        {
          "Bundle ID" = "com.apple.CharacterPaletteIM";
          InputSourceKind = "Non Keyboard Input Method";
        }
        {
          InputSourceKind = "Keyboard Layout";
          "KeyboardLayout ID" = -69;
          "KeyboardLayout Name" = "Croatian-PC";
        }
        {
          "Bundle ID" = "com.apple.PressAndHold";
          InputSourceKind = "Non Keyboard Input Method";
        }
        {
          "Bundle ID" = "com.apple.inputmethod.ironwood";
          InputSourceKind = "Non Keyboard Input Method";
        }
      ];
      AppleSelectedInputSources = [
        {
          InputSourceKind = "Keyboard Layout";
          "KeyboardLayout ID" = -69;
          "KeyboardLayout Name" = "Croatian-PC";
        }
        {
          "Bundle ID" = "com.apple.PressAndHold";
          InputSourceKind = "Non Keyboard Input Method";
        }
      ];
    };
  };
}
