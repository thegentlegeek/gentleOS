{ 
  pkgs, 
  ... 
}:

{
  environment.systemPackages = with pkgs; [
    libva-utils # provides vainfo, for verifying VA-API hardware decode
    (chromium.override {
      enableWideVine = true; # stupid proprietary DRM from Google
      commandLineArgs = [ # these options are to enable hardware acceleration
        "--enable-features=VaapiVideoDecoder,VaapiVideoEncoder"
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

