{ 
  ... 
}:

{
  programs.kitty = {
    enable = true;
    shellIntegration.enableBashIntegration = true;
    shellIntegration.enableFishIntegration = true;
    settings = {
      enable_audio_bell = false;
      window_padding_width = 8;
      tab_bar_edge = "top";
      confirm_os_window_close = 0;
    };
  };
}