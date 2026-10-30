# Theming

One base16 scheme themes everything: the desktop and its apps, the login screen,
the console and the wallpaper. [Stylix](https://github.com/danth/stylix) does
the work. This folder holds its configuration, which both NixOS and Home Manager
import, so the system and the desktop always agree.

```
modules/shared/
├── stylix.nix          # gentleOS.theme options, wallpaper recipes, Stylix config
└── wallpapers/
    ├── recolor.py      # recolors a flat-color wallpaper to the scheme
    └── *.png, *.jpg    # source images
```

## Changing the theme

Change the defaults of `gentleOS.theme` in `stylix.nix`:

```nix
options.gentleOS.theme = {
  scheme = lib.mkOption { default = "eris"; ... };              # any pkgs.base16-schemes file, without .yaml
  wallpaper = lib.mkOption { default = "stripes-mirror"; ... };  # a recipe from `wallpapers`
};
```

Change the defaults rather than setting `stylix.*` directly: the flake's
`screenshotHomes` sets `gentleOS.theme` per theme to capture the README
screenshots.

List the available schemes:

```bash
ls $(nix build --no-link --print-out-paths nixpkgs#base16-schemes)/share/themes
```

You can preview them in the [Tinted Theming gallery](https://tinted-theming.github.io/tinted-gallery/).
For a light scheme, also set `stylix.polarity = "light"`.

### Applying it

Home Manager is standalone, so the change takes two switches:

```bash
home-manager switch --flake ~/gentleOS#justin        # desktop: Hyprland, Quickshell, terminal, GTK/Qt, Firefox, ...
sudo nixos-rebuild switch --flake ~/gentleOS#zbook   # system: login screen (regreet), console, boot splash
```

Apps that were already open (Firefox, GTK apps) pick up the change after a
restart.

A theme change only rebuilds the small generated files that contain colors
(configs, GTK/Kvantum themes, the wallpaper), so it takes seconds. See
[Why theme changes stay fast](#why-theme-changes-stay-fast).

## Wallpapers

The wallpaper isn't a fixed image: `stylix.image` is a derivation that recolors
a source image to the active scheme, so it changes with `scheme`. Because
`base16Scheme` is set explicitly, Stylix never derives colors from the
wallpaper, and the wallpaper can safely depend on the colors.

### How the recolor works

The source wallpapers are flat-color designs: a background plus a few solid
colors, with antialiased edges. Each recipe maps every source color onto a
scheme color. `recolor.py` (numpy + Pillow) treats each pixel as the background
plus some fraction of the nearest source color, then rebuilds it from the
replacement colors, so edges stay smooth with no fringing.

A recipe in `stylix.nix` looks like this:

```nix
stripes-ramp = {
  src = ./wallpapers/nixos-wallpaper-custom.png;
  bg = "0e091d";                # source background; always becomes base00
  colors = {
    "74316b" = c.base03;        # source hex = scheme color
    ...
    "ff6565" = c.base0A;
  };
};
```

A replacement can also be a blend, `"${c.base0E}+${c.base08}@0.25"`: base0E
moved 25% of the way toward base08. A blend creates a color that isn't in the
scheme, so only the original `stripes` recipe uses it.

### Recipes

| Recipe | Source | Mapping |
|---|---|---|
| `stripes-mirror` | diagonal stripes | Only scheme colors, mirrored: base0E, base04, base03 (middle), base04, base0E. Snowflake: base04 and base0E. |
| `stripes-ramp` | diagonal stripes | The designer's mapping: a base03 → base06 ramp ending in base0A. The source image *is* the `tarot` scheme, so this reproduces it there exactly, except that the snowflake's dark arms are base0A instead of base02, so they stay visible in low-contrast schemes. |
| `stripes` | diagonal stripes | A blended gradient from base0E to base08. Smooth in every scheme, but the middle three stripes are blends, not scheme colors. |
| `snowflake` | NixOS snowflake | Six accents onto their matching hues (base08, 0A, 0B, 0C, 0D, 0E). |

Some lessons from building these:

- **The accent slots don't form a gradient.** base16 fixes what each accent
  slot is for (red-ish, orange-ish, ...), not its order or brightness.
  base0F especially varies: brown in Eris and Gruvbox, pink in Spaceduck, blue
  in Nord. Assigning five accents to five stripes looked random.
- **base00 → base07 is a ramp.** Schemes design the neutrals to step from
  background to foreground, so they make a dependable gradient. Some schemes
  repeat a step (`standardized-dark` has base03 = base04), which flattens
  recipes that rely on those two.
- **Low-contrast schemes swallow the dim end.** In `lime`, base02 and base03
  are barely lighter than the background; use base03 or higher for anything
  that should stay visible.

### Adding a wallpaper

1. Put the image in `wallpapers/`. It should be flat-color (vector art, a logo
   or a minimal design). Photos and gradients don't recolor this way.
2. Find its colors. Real colors have large pixel counts; the long tail is
   antialiasing:
   ```bash
   nix shell nixpkgs#imagemagick -c magick wallpapers/<image> -format %c histogram:info:- | sort -rn | head
   ```
3. Add a recipe to `wallpapers` in `stylix.nix`: the background hex as `bg`,
   each other color mapped to a scheme slot.
4. Preview it without switching:
   ```bash
   nix build --no-link --print-out-paths .#homeConfigurations.justin.config.stylix.image
   ```
   This builds the default recipe, so change the default first to test a new
   one.

For a photo, the option is a color lookup table: `lutgen` (in nixpkgs) remaps
every pixel toward the palette. It gives a tinted look rather than exact
colors, and isn't wired up yet. To use an image unchanged, set `stylix.image`
to its path.

## Where the colors go

- **Stylix targets.** Most apps are themed by Stylix's own targets: GTK,
  Qt/Kvantum, Firefox, the terminal, Hyprland, Vencord, the login screen, the
  console and the boot splash.
- **Quickshell.** `modules/home/window-managers/hyprland/quickshell/default.nix`
  writes base00–base0F and the fonts into `Theme.qml.json`, which the shell
  reads.
- **Custom configs.** Starship reads `config.lib.stylix.colors` directly.
- **Exceptions.** In `users/justin/home.nix`, the OpenCode target is off,
  since Stylix generates OpenCode 1 themes and v2 uses its "system" theme. The Qt target is turned on explicitly, because
  it isn't automatic under standalone Home Manager.

Fonts (JetBrains Mono Nerd Font, Liberation Sans, DejaVu Serif), the cursor
(Bibata Modern Ice) and sizes are set in `stylix.nix` and follow the same path.

## Why theme changes stay fast

Nix rebuilds anything whose inputs change, and the binary cache can't help with
anything that contains your colors. That's fine for generated config files.
It's expensive when the colors end up inside a package that other packages
depend on.

Stylix's **package overlays** do exactly that: they patch the scheme into
gtksourceview (and nixos-icons). Every package built on gtksourceview then
changes too, and has to be compiled from source on every theme change: here,
inkscape and bottles, which took minutes. `users/justin/home.nix` therefore
sets `stylix.overlays.enable = false`. Editor syntax colors are still themed:
the gtksourceview target writes the style to
`~/.local/share/gtksourceview-*/styles/stylix.xml` instead.

The NixOS side keeps the overlays, since only gnome-calculator depends on
gtksourceview there.

If a theme change ever starts compiling large packages again, look for a target
or overlay that changes a package rather than writing a file.
