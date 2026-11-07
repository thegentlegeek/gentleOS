# Wallpapers drawn from scratch in a base16 scheme's colors by generate.py
# (styles.nix). Used by modules/shared/stylix.nix for stylix.image and by the
# flake's wallpapers output. Built with runCommandLocal:
# no binary cache has an image in your colors, so asking one first only adds
# latency (or timeouts).
{ pkgs }:

let
  inherit (pkgs) lib;
  styles = import ./styles.nix;
in
{
  # Every wallpaper name.
  names = builtins.attrNames styles;

  # name: a style from names. palette: base00-base0F as bare hex plus slug, as
  # config.lib.stylix.colors or base16.nix's mkSchemeAttrs give them.
  render =
    {
      name,
      palette,
      width ? 3840,
      height ? 2400,
    }:
    let
      g = styles.${name};
      python = pkgs.python3.withPackages (ps: [ ps.numpy ps.pillow ps.pycairo ]);
      colors = map (i: palette."base0${i}") [ "0" "1" "2" "3" "4" "5" "6" "7" "8" "9" "A" "B" "C" "D" "E" "F" ];
    in
    pkgs.runCommandLocal "wallpaper-${name}-${palette.slug}.png" { } ''
      ${python}/bin/python3 ${./generate.py} ${name} $out ${toString width}x${toString height} ${toString g.seed} \
        ${lib.escapeShellArg (builtins.toJSON g.params)} ${lib.concatStringsSep " " colors}
    '';
}
