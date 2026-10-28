{
  config,
  ...
}:

let
  colors = config.lib.stylix.colors.withHashtag;
in {
  services = {
    dunst = {
      enable = true;
      settings = {
        global = {
          width = "(300,700)";
          # (min, max) per notification since dunst 1.12; 1.11 and older read only
          # a max, which is how "(500,800)" used to work and now forces 500px+.
          height = "(0,300)";
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
          background = "${colors.base0E}d9"; # ~85% opaque, blurred (hyprland.lua)
          foreground = "${colors.base07}";
          frame_color = "${colors.base0E}";
          separator_color = "${colors.base07}";
          highlight = "${colors.base07}";
        };
        urgency_low = {
          background = "${colors.base0E}d9"; # ~85% opaque, blurred (hyprland.lua)
          foreground = "${colors.base07}";
          frame_color = "${colors.base0E}";
          highlight = "${colors.base07}";
        };
        urgency_high = {
          background = "${colors.base08}d9";
          foreground = "${colors.base07}";
          frame_color = "${colors.base08}";
          highlight = "${colors.base07}";
        };
      };
    };
  };
}