{
  pkgs,
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
  
  inherit (config.lib.formats.rasi) mkLiteral;
  rofi-theme = {
    "*" = {
      foreground = mkLiteral "${stylix06}";
      background-color = mkLiteral "transparent";
      text-color = mkLiteral "${stylix07}";
      backlight = mkLiteral "${stylix0B}";
    };
    "window" = {
      children = mkLiteral "[mainbox]";
      location = mkLiteral "center";
      border = mkLiteral "2px";
      border-color = mkLiteral "${stylix0E}";
      border-radius = mkLiteral "10px"; 
      spacing = mkLiteral "0";
      width = mkLiteral "25%";
    };
    "mainbox" = {
      children = mkLiteral "[inputbar, message, listview]";
    };
    "inputbar" = {
      color = mkLiteral "${stylix06}";
      background-color = mkLiteral "${stylix02}";
      padding = mkLiteral "8px";
    };
    "listview" = {
      background-color = mkLiteral "${stylix00}";
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
      background-color = mkLiteral "${stylix0D}";
    };
  };

in {
  programs.rofi = {
    enable = true;
    theme = rofi-theme;
    terminal = "${pkgs.kitty}/bin/kitty";
  };
}