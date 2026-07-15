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
    # Snappy keyboard: short initial delay before repeat, then the fastest repeat.
    InitialKeyRepeat = 10;
    KeyRepeat = 1;
    # Disable press-and-hold accent popover so holding a key repeats it instead.
    ApplePressAndHoldEnabled = false;
    # Instant window open/close/resize animations.
    NSAutomaticWindowAnimationsEnabled = false;
    NSWindowResizeTime = 0.001;
    # Spring-loaded folders enabled with a 0.5s hover delay.
    "com.apple.springing.enabled" = true;
    "com.apple.springing.delay" = 0.5;
    # Always show scrollbars and jump to the clicked spot when paging.
    AppleShowScrollBars = "Always";
    AppleScrollerPagingBehavior = true;
    # Full keyboard access: Tab moves focus to all controls.
    AppleKeyboardUIMode = 3;
    # Expand save and print panels by default.
    NSNavPanelExpandedStateForSaveMode = true;
    NSNavPanelExpandedStateForSaveMode2 = true;
    PMPrintingExpandedStateForPrint = true;
    PMPrintingExpandedStateForPrint2 = true;
    # Medium (32px) sidebar icon size in Finder and elsewhere.
    NSTableViewDefaultSizeMode = 2;
  };
  system.defaults.LaunchServices.LSQuarantine = true;
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
    # Show the full POSIX path in the Finder window title.
    _FXShowPosixPathInTitle = true;
    # Show hidden dotfiles in Finder.
    AppleShowAllFiles = true;
    # Search the current folder by default instead of the whole Mac.
    FXDefaultSearchScope = "SCcf";
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
    # Lightest touch for Force Click and haptic feedback thresholds.
    FirstClickThreshold = 0;
    SecondClickThreshold = 0;
  };
  system.defaults.screencapture = {
    # No drop shadow around captured windows.
    disable-shadow = true;
  };
  system.defaults.screensaver = {
    # Require the password 10s after sleep/screensaver starts.
    askForPasswordDelay = 10;
  };

  # Remap the non-US "tilde" key (ISO layouts) to the expected position.
  system.keyboard.enableKeyMapping = true;
  system.keyboard.nonUS.remapTilde = true;

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

    # Disable Finder animations (window open, info panel, etc.) for snappier feel.
    "com.apple.finder" = {
      DisableAllAnimations = true;
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

    # Hide every Spotlight search-result category. Indexing and Spotlight
    # activity are disabled system-wide in services.nix as well.
    "com.apple.Spotlight" = {
      orderedItems = [
        {
          enabled = 0;
          name = "APPLICATIONS";
        }
        {
          enabled = 0;
          name = "MENU_EXPRESSION";
        }
        {
          enabled = 0;
          name = "CONTACT";
        }
        {
          enabled = 0;
          name = "MENU_CONVERSION";
        }
        {
          enabled = 0;
          name = "MENU_DEFINITION";
        }
        {
          enabled = 0;
          name = "DOCUMENTS";
        }
        {
          enabled = 0;
          name = "EVENT_TODO";
        }
        {
          enabled = 0;
          name = "DIRECTORIES";
        }
        {
          enabled = 0;
          name = "FONTS";
        }
        {
          enabled = 0;
          name = "IMAGES";
        }
        {
          enabled = 0;
          name = "MESSAGES";
        }
        {
          enabled = 0;
          name = "MOVIES";
        }
        {
          enabled = 0;
          name = "MUSIC";
        }
        {
          enabled = 0;
          name = "MENU_OTHER";
        }
        {
          enabled = 0;
          name = "PDF";
        }
        {
          enabled = 0;
          name = "PRESENTATIONS";
        }
        {
          enabled = 0;
          name = "MENU_SPOTLIGHT_SUGGESTIONS";
        }
        {
          enabled = 0;
          name = "SPREADSHEETS";
        }
        {
          enabled = 0;
          name = "SYSTEM_PREFS";
        }
        {
          enabled = 0;
          name = "TIPS";
        }
        {
          enabled = 0;
          name = "BOOKMARKS";
        }
        {
          enabled = 0;
          name = "SOURCE";
        }
      ];
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
