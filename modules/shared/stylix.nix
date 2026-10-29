{
 config,
 lib,
 pkgs,
 ...
}:

let
  # Flat-color wallpapers recolored to the active scheme by recolor.py: each
  # source color maps onto a scheme color (A+B@T mixes A toward B by T).
  # Pick one with `wallpaper` below.
  c = config.lib.stylix.colors;
  wallpapers = {
    # NixOS snowflake: six accents onto the matching base16 hues.
    snowflake = {
      src = ./wallpapers/nixos-standardized-dark.png;
      bg = "222222";
      colors = {
        "21c992" = c.base0C;
        "00a3f2" = c.base0D;
        "b46ee0" = c.base0E;
        "e15d67" = c.base08;
        "5db129" = c.base0B;
        "e1b31a" = c.base0A;
      };
    };
    # Diagonal stripes: the purple-to-coral gradient becomes base0E to base08;
    # the snowflake's dark arms are base0E dimmed halfway into the background.
    stripes = {
      src = ./wallpapers/nixos-wallpaper-custom.png;
      bg = "0e091d";
      colors = {
        "74316b" = c.base0E;
        "8c406f" = "${c.base0E}+${c.base08}@0.25";
        "aa556f" = "${c.base0E}+${c.base08}@0.5";
        "c4686d" = "${c.base0E}+${c.base08}@0.75";
        "ff6565" = c.base08;
        "4b2054" = "${c.base0E}+${c.base00}@0.5";
      };
    };
  };

  recolor =
    name:
    let
      w = wallpapers.${name};
      python = pkgs.python3.withPackages (ps: [ ps.numpy ps.pillow ]);
    in
    pkgs.runCommand "wallpaper-${name}-${c.slug}.png" { } ''
      ${python}/bin/python3 ${./wallpapers/recolor.py} ${w.src} $out \
        ${w.bg}:${c.base00} ${lib.concatStringsSep " " (lib.mapAttrsToList (from: to: "${from}:${to}") w.colors)}
    '';
in
{
  stylix = {
    enable = true;
    polarity = "dark";
    image = recolor "stripes";
    base16Scheme = "${pkgs.base16-schemes}/share/themes/lime.yaml";
    
    cursor = {
     package = pkgs.bibata-cursors;
     name = "Bibata-Modern-Ice";
     size = 24;
    };

    fonts = {
      monospace = {
        package = pkgs.nerd-fonts.jetbrains-mono;
        name = "JetBrainsMono Nerd Font Mono";
      };
      sansSerif = {
        package = pkgs.liberation_ttf;
        name = "Liberation Sans Regular";
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
  };
}
