{ 
  config,
  lib,
  ...
}:

{
  options.myColors = {
    # Pull in Stylix colors
    stylix00 = lib.mkOption {
      type = lib.types.str;
      default = config.lib.stylix.colors.withHashtag.base00;
      description = "stylix00 color from Stylix";
    };

    stylix01 = lib.mkOption {
      type = lib.types.str;
      default = config.lib.stylix.colors.withHashtag.base01;
      description = "stylix01 color from Stylix";
    };

    stylix02 = lib.mkOption {
      type = lib.types.str;
      default = config.lib.stylix.colors.withHashtag.base02;
      description = "stylix01 color from Stylix";
    };

    stylix03 = lib.mkOption {
      type = lib.types.str;
      default = config.lib.stylix.colors.withHashtag.base03;
      description = "stylix01 color from Stylix";
    };

    stylix04 = lib.mkOption {
      type = lib.types.str;
      default = config.lib.stylix.colors.withHashtag.base04;
      description = "stylix01 color from Stylix";
    };

    stylix05 = lib.mkOption {
      type = lib.types.str;
      default = config.lib.stylix.colors.withHashtag.base05;
      description = "stylix01 color from Stylix";
    };

    stylix06 = lib.mkOption {
      type = lib.types.str;
      default = config.lib.stylix.colors.withHashtag.base06;
      description = "stylix01 color from Stylix";
    };

    stylix07 = lib.mkOption {
      type = lib.types.str;
      default = config.lib.stylix.colors.withHashtag.base07;
      description = "stylix01 color from Stylix";
    };

    stylix08 = lib.mkOption {
      type = lib.types.str;
      default = config.lib.stylix.colors.withHashtag.base08;
      description = "stylix01 color from Stylix";
    };

    stylix09 = lib.mkOption {
      type = lib.types.str;
      default = config.lib.stylix.colors.withHashtag.base09;
      description = "stylix01 color from Stylix";
    };

    stylix0A = lib.mkOption {
      type = lib.types.str;
      default = config.lib.stylix.colors.withHashtag.base0A;
      description = "stylix01 color from Stylix";
    };

    stylix0B = lib.mkOption {
      type = lib.types.str;
      default = config.lib.stylix.colors.withHashtag.base0B;
      description = "stylix01 color from Stylix";
    };

    stylix0C = lib.mkOption {
      type = lib.types.str;
      default = config.lib.stylix.colors.withHashtag.base0C;
      description = "stylix01 color from Stylix";
    };

    stylix0D = lib.mkOption {
      type = lib.types.str;
      default = config.lib.stylix.colors.withHashtag.base0D;
      description = "stylix01 color from Stylix";
    };

    stylix0E = lib.mkOption {
      type = lib.types.str;
      default = config.lib.stylix.colors.withHashtag.base0E;
      description = "stylix01 color from Stylix";
    };

    stylix0F = lib.mkOption {
      type = lib.types.str;
      default = config.lib.stylix.colors.withHashtag.base0F;
      description = "stylix01 color from Stylix";
    };
  };
}