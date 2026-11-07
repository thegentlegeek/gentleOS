{
 config,
 gentleInputs,
 lib,
 pkgs,
 ...
}:

let
  theme = config.gentleOS.theme;
  wallpapers = import ../../pkgs/wallpapers { inherit pkgs; };
  # The chosen theme. gentle-theme (the theme picker) writes and commits it.
  defaults = lib.importJSON config.gentleOS.themeFile;
  # Each leaf a default of its own, so setting one value keeps the others.
  mkDefaults = lib.mapAttrsRecursiveCond (value: !lib.isDerivation value) (_: lib.mkDefault);
in
{
  # The active theme. Its defaults come from theme.json; capturing
  # screenshots also sets it per theme, so change
  # theme.json rather than stylix.* below.
  options.gentleOS.themeFile = lib.mkOption {
    type = lib.types.path;
    default = ./theme.json;
    description = "JSON file with the scheme and wallpaper. Keep it in your own flake, since the theme picker writes and commits it. Set it on both the NixOS and Home Manager sides.";
  };

  options.gentleOS.theme = {
    scheme = lib.mkOption {
      type = lib.types.str;
      default = defaults.scheme;
      description = "A scheme in the tinted-schemes input as <system>/<name>, without .yaml (e.g. base16/nord, base24/one-dark).";
    };
    wallpaper = lib.mkOption {
      type = lib.types.enum wallpapers.names;
      default = defaults.wallpaper;
      description = "Wallpaper drawn in the scheme's colors by generate.py: a style from pkgs/wallpapers/styles.nix.";
    };
  };

  config.stylix = {
    enable = true;
    # Light or dark as the scheme declares it (every tinted scheme has a variant).
    polarity = config.lib.stylix.colors.variant;
    # Stylix overlays patch gtksourceview (and nixos-icons) with the scheme, which
    # forces local source builds of everything depending on it (inkscape, bottles,
    # gnome-calculator) on every theme change. The gtksourceview target still
    # themes via ~/.local/share, and no app here asks for the overlay's scheme.
    overlays.enable = false;
    image = wallpapers.render { name = theme.wallpaper; palette = config.lib.stylix.colors; };
    base16Scheme = "${gentleInputs.tinted-schemes}/${theme.scheme}.yaml";

    cursor = mkDefaults {
     package = pkgs.bibata-cursors;
     name = "Bibata-Modern-Ice";
     size = 24;
    };

    fonts = mkDefaults {
      monospace = {
        package = pkgs.nerd-fonts.jetbrains-mono;
        name = "JetBrainsMono Nerd Font Mono";
      };
      sansSerif = {
        package = pkgs.liberation_ttf;
        name = "Liberation Sans";
      };
      serif = {
        package = pkgs.dejavu_fonts;
        name = "DejaVu Serif";
      };
      sizes = {
        applications = 10;
        desktop = 10;
        terminal = 10;
        popups = 10;
      };
    };

    # Terminal background alpha, also the Quickshell bar's (barAlpha in
    # quickshell/default.nix): the background is translucent and blurred, but
    # text stays fully opaque.
    opacity.terminal = lib.mkDefault 0.8;
  };
}
