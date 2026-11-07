# Wallpapers drawn from scratch by generate.py in the scheme's colors, one
# 3840x2400 image for both 16:10 and 16:9 screens (every
# design is centered, so the crop loses nothing). Seeds and params are the
# settings picked on the wallpaper studies board. Preview one with
# `nix build .#wallpapers.<style>.base16.<scheme>`.
{
  layered-ridges = { seed = 5246; params = { layers = 6; rough = 0.95; glow = 1; }; };
  contours = { seed = 3075; params = { levels = 20; relief = 3.2; fill = 0.8; }; };
  windlines = { seed = 234; params = { density = 1.6; curl = 2.6; glow = 0.55; }; };
  flow-engraving = { seed = 4532; params = { spacing = 8; weight = 2; curl = 3; glow = 0.45; logo = 680; vary = 1; }; };
  prism-shards = { seed = 7271; params = { facet = 105; colors = 1; accent = 0.6; contrast = 0.4; }; };
  woven-ribbons = { seed = 3846; params = { wave = 170; width = 58; depth = 1; size = 420; cutout = 75; bars = 7; }; };
  sunburst = { seed = 7; params = { rays = 18; twist = 0.5; soft = 0; bloom = 0; }; };
}
