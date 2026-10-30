{
 config,
 inputs,
 lib,
 pkgs,
 ...
}:

let
  theme = config.gentleOS.theme;

  # Flat-color wallpapers recolored to the active scheme by recolor.py: each
  # source color maps onto a scheme color (A+B@T mixes A toward B by T).
  # Pick one with gentleOS.theme.wallpaper below.
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
    # Diagonal stripes, scheme colors only. The original is the tarot scheme:
    # a base03-base06 ramp ending in base0A, so this reproduces it there. The
    # snowflake's dark arms are base0A (tarot: base02) to stay visible in
    # low-contrast schemes.
    stripes-ramp = {
      src = ./wallpapers/nixos-wallpaper-custom.png;
      bg = "0e091d";
      colors = {
        "74316b" = c.base03;
        "8c406f" = c.base04;
        "aa556f" = c.base05;
        "c4686d" = c.base06;
        "ff6565" = c.base0A;
        "4b2054" = c.base0A;
      };
    };
    # Diagonal stripes, scheme colors only, mirrored: base0E, then a dip
    # through base04 to base03 in the middle, and back out to base0E.
    stripes-mirror = {
      src = ./wallpapers/nixos-wallpaper-custom.png;
      bg = "0e091d";
      colors = {
        "74316b" = c.base0E;
        "8c406f" = c.base04;
        "aa556f" = c.base03;
        "c4686d" = c.base04;
        "ff6565" = c.base0E;
        "4b2054" = c.base0E;
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
  # The active theme. Also set per theme by the flake's screenshotHomes (README
  # screenshots), so change the defaults here rather than stylix.* below.
  options.gentleOS.theme = {
    scheme = lib.mkOption {
      type = lib.types.str;
      default = "apathy";
      description = "base16 scheme: a file name (without .yaml) in the tinted-schemes input's base16/.";
    };
    wallpaper = lib.mkOption {
      type = lib.types.enum (builtins.attrNames wallpapers);
      default = "stripes-mirror";
      description = "Wallpaper, recolored to the scheme.";
    };
  };

  config.stylix = {
    enable = true;
    polarity = "dark";
    image = recolor theme.wallpaper;
    # Trailing comments are stripped first: base16.nix's YAML parser silently
    # drops any line whose comment holds a colon (bogota's "# derived: ...").
    base16Scheme =
      let
        stripComment =
          line:
          let
            m = builtins.match ''(.*")[[:space:]]+#.*'' line;
          in
          if m == null then line else builtins.head m;
        yaml = builtins.unsafeDiscardStringContext (
          builtins.readFile "${inputs.tinted-schemes}/base16/${theme.scheme}.yaml"
        );
      in
      builtins.toFile "${theme.scheme}.yaml" (
        lib.concatMapStringsSep "\n" stripComment (lib.splitString "\n" yaml)
      );
    
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

    # Terminal background alpha, also the Quickshell bar's (barAlpha in
    # quickshell/default.nix): the background is translucent and blurred, but
    # text stays fully opaque.
    opacity.terminal = 0.8;
  };
}
