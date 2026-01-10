{ 
  pkgs, 
  ... 
}:

{
  environment.systemPackages = with pkgs; [
    (chromium.override {
      enableWideVine = true; # stupid proprietary DRM from Google
      commandLineArgs = [ # these options are to enable hardware acceleration
        "--enable-features=VaapiVideoDecodeLinuxGL"
        "--ignore-gpu-blocklist"
        "--enable-zero-copy"
        ];
      })
  ];
  programs.chromium = {
    extraOpts = {
      # Security/Privacy
      "BrowserSignin" = 0;
      "SyncDisabled" = true;
      "PasswordManagerEnabled" = false;
      # QoL
      "HomepageIsNewTabPage" = true;
      "RestoreOnStartup" = 1;
      "ScreenCaptureAllowed" = true;
      "DeviceSecondFactorAuthentication" = true;
    };
  };
}

