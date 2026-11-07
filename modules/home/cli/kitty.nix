{ 
  lib,
  ... 
}:

{
  programs.kitty = {
    enable = true;
    shellIntegration.enableBashIntegration = lib.mkDefault true;
    shellIntegration.enableFishIntegration = lib.mkDefault true;
    settings = lib.mapAttrs (_: lib.mkDefault) {
      enable_audio_bell = false;
      window_padding_width = 8;
      tab_bar_edge = "top";
      confirm_os_window_close = 0;
    };
  };
}