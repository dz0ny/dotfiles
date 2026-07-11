{
  # macOS system defaults managed by nixmac.

  system.defaults.NSGlobalDomain = {
    "com.apple.swipescrolldirection" = false;
    AppleShowAllExtensions = true;
    InitialKeyRepeat = 15;
    KeyRepeat = 2;
  };
  system.defaults.WindowManager = {
    AppWindowGroupingBehavior = true;
    AutoHide = true;
    EnableTiledWindowMargins = false;
    HideDesktop = true;
  };
  system.defaults.dock = {
    minimize-to-application = true;
    orientation = "left";
    show-recents = false;
    tilesize = 78;
  };
  system.defaults.finder = {
    FXEnableExtensionChangeWarning = false;
    FXPreferredViewStyle = "Nlsv";
    ShowPathbar = true;
    _FXSortFoldersFirst = true;
  };
  system.defaults.magicmouse = {
    MouseButtonMode = "OneButton";
  };
  system.defaults.menuExtraClock = {
    ShowDate = 1;
  };
  system.defaults.trackpad = {
    TrackpadThreeFingerTapGesture = 2;
  };}
