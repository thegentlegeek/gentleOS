{
  pkgs,
  config,
  ...
}:

let
  colors = config.lib.stylix.colors.withHashtag;
  
  inherit (config.lib.formats.rasi) mkLiteral;
  rofi-theme = {
    "*" = {
      foreground = mkLiteral "${colors.base06}";
      background-color = mkLiteral "transparent";
      text-color = mkLiteral "${colors.base07}";
      backlight = mkLiteral "${colors.base0B}";
    };
    "window" = {
      children = mkLiteral "[mainbox]";
      location = mkLiteral "center";
      border = mkLiteral "2px";
      border-color = mkLiteral "${colors.base0E}";
      border-radius = mkLiteral "10px"; 
      spacing = mkLiteral "0";
      width = mkLiteral "25%";
    };
    "mainbox" = {
      children = mkLiteral "[inputbar, message, listview]";
    };
    "inputbar" = {
      color = mkLiteral "${colors.base06}";
      background-color = mkLiteral "${colors.base02}";
      padding = mkLiteral "8px";
    };
    "listview" = {
      background-color = mkLiteral "${colors.base00}";
      padding = mkLiteral "8px";
    };
    "element" = {
      padding = mkLiteral "5px";
      #vertical-align = mkLiteral "0.5";
      border-radius = mkLiteral "4px";
      border = mkLiteral "0px";
      background-color = mkLiteral "transparent";
    };
    "element selected.normal" = {
      background-color = mkLiteral "${colors.base0D}";
    };
  };

in {
  programs.rofi = {
    enable = true;
    theme = rofi-theme;
    terminal = "${pkgs.kitty}/bin/kitty";
  };
}