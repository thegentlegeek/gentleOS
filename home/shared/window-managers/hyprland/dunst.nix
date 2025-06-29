{
  config,
  ...
}:

let
  stylix00 = config.myColors.stylix00;
  stylix01 = config.myColors.stylix01;
  stylix02 = config.myColors.stylix02;
  stylix03 = config.myColors.stylix03;
  stylix04 = config.myColors.stylix04;
  stylix05 = config.myColors.stylix05;
  stylix06 = config.myColors.stylix06;
  stylix07 = config.myColors.stylix07;
  stylix08 = config.myColors.stylix08;
  stylix09 = config.myColors.stylix09;
  stylix0A = config.myColors.stylix0A;
  stylix0B = config.myColors.stylix0B;
  stylix0C = config.myColors.stylix0C;
  stylix0D = config.myColors.stylix0D;
  stylix0E = config.myColors.stylix0E;
  stylix0F = config.myColors.stylix0F;
in {
  services = {
    dunst = {
      enable = true;
      settings = {
        global = {
          width = "(300,700)";
          height = "(500,800)";
          offset = "0x0";
          origin = "top-center";
          gap_size = 5;
          line_height = 1;
          font = "JetBrainsMono Nerd Font Mono 10";
          corner_radius = 10;

          #transparency = 10;color scheme generator
          #font = "Droid Sans 9";
        };

        urgency_normal = {
          background = "${stylix0E}";
          foreground = "${stylix07}";
          frame_color = "${stylix0E}";
          separator_color = "${stylix07}";
          highlight = "${stylix07}";
        };
        urgency_low = {
          background = "${stylix0E}";
          foreground = "${stylix07}";
          frame_color = "${stylix0E}";
          highlight = "${stylix07}";
        };
        urgency_high = {
          background = "${stylix08}";
          foreground = "${stylix07}";
          frame_color = "${stylix08}";
          highlight = "${stylix07}";
        };
      };
    };
  };
}