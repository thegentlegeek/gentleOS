# Theming

One base16 (or base24) scheme themes everything: the desktop and its apps, the login screen,
the console and the wallpaper. [Stylix](https://github.com/danth/stylix) does
the work. This folder holds its configuration, which both NixOS and Home Manager
import, so the system and the desktop always agree. The wallpapers are a
package of their own in `pkgs/wallpapers/`.

```
modules/shared/
├── theme.json          # the default scheme and wallpaper; yours is in your flake
└── stylix.nix          # gentleOS.theme options and Stylix config

pkgs/wallpapers/
├── default.nix         # render { name, palette }: the wallpaper derivation
├── styles.nix          # seed and settings of each style
└── generate.py         # draws the wallpapers from the scheme's colors
```

## Changing the theme

Press `SUPER + W` to open the theme picker, a floating window you move and resize
like any other. It stays open while you use other apps, so you can see a preview
in them.

1. Pick a scheme, filtering by name, Dark/Light and Base16/Base24, and a wallpaper.
   The picker shows the wallpaper in that scheme, the scheme's 16 colors and a small
   prompt-and-code sample, which you can toggle off to see the whole wallpaper. The
   sample needs no build, but it only approximates your apps, as each one maps
   the colors its own way.
2. **Try on desktop** applies it to the desktop. A new scheme takes a Home Manager
   build; a new wallpaper in the current scheme only swaps the image. The lock
   screen keeps the old wallpaper until you **Keep** a wallpaper-only try.
3. **Keep** commits `theme.json` and switches both Home Manager and the system,
   which asks for your password. **Revert** puts the old theme back.

| Key | Action |
|-----|--------|
| `Up` / `Down` | Pick a scheme |
| `Left` / `Right` | Pick a wallpaper, while the search box is empty |
| `Tab` | Move between search and the filters; `Left` / `Right` change a filter |
| `Enter` | Try on desktop; with a search that doesn't include the selection, select the top match first |
| `Ctrl+Enter` | Keep |
| `Ctrl+R` | Revert |
| `Ctrl+S` | Show or hide the sample |
| `Esc` | Close the picker, leaving any theme you're trying in place |

The picker is `quickshell/shell/ThemePicker.qml`, a separate process from the shell,
so trying a scheme restarts the shell without closing the window. Its backend is
`gentle-theme` (`quickshell/theme.sh`), which you can also run from a terminal.

To change the theme by hand, edit `theme.json` and apply it as below:

```json
{
  "scheme": "base16/<scheme>",
  "wallpaper": "<name>"
}
```

`scheme` is `<system>/<name>` without `.yaml`. `wallpaper` is a style from
`styles.nix`. Change `theme.json` rather than setting `stylix.*` directly.

Schemes come from the `tinted-schemes` flake input, a pin of
[tinted-theming/schemes](https://github.com/tinted-theming/schemes) rather than
nixpkgs' older `base16-schemes` snapshot, so new ones arrive when you update
gentleOS. The theme picker lists them all. In a checkout of this repo, you can
also list them with:

```bash
ls $(nix flake archive --json | jq -r '.inputs."tinted-schemes".path')/base16
ls $(nix flake archive --json | jq -r '.inputs."tinted-schemes".path')/base24
```

Many schemes exist only as base24 (`one-dark`, `cobalt2`, the `lumina-*`
family, ...); use one as `"base24/<name>"`. Stylix themes from base00-base0F
either way, and only a few targets (starship, k9s) use base24's extra colors.

The scheme file goes to Stylix unchanged, so Stylix's own YAML parser
(base16.nix) reads it. It reads all but 29 of the schemes. The ones it can't
are `dracula`, `ascendancy`, `x`, `abyssal`, `alucard` and the city family
(`berlin`, `bogota`, `london`, `paris`, ...); those fail at evaluation time, and
the picker shows their colors but says they can't be applied. It doesn't list `base16/cyberpunk.yml`,
because Stylix is only given `.yaml` paths.

You can preview them in the [Tinted Theming gallery](https://tinted-theming.github.io/tinted-gallery/).
Light or dark comes from the scheme's own `variant`.

### Applying it

Home Manager is standalone, so the change takes two switches:

```bash
home-manager switch --flake ~/nix-config#YOUR_USERNAME   # desktop: Hyprland, Quickshell, terminal, GTK/Qt, Firefox, ...
sudo nixos-rebuild switch --flake ~/nix-config#YOUR_HOSTNAME   # system: login screen (regreet), console, boot splash
```

Apps that were already open (Firefox, GTK apps) pick up the change after a
restart.

A theme change only rebuilds the small generated files that contain colors
(configs, GTK/Kvantum themes, the wallpaper), so it takes seconds. See
[Why theme changes stay fast](#why-theme-changes-stay-fast).

## Wallpapers

Setting `gentleOS.theme.image` to your own file replaces what's described here,
and the theme picker then only picks schemes.

The wallpaper isn't a fixed image: `stylix.image` is a derivation that draws it
from scratch in the active scheme's colors (`generate.py`), so it changes with
`scheme`. It lives in `pkgs/wallpapers/`, whose `render` function builds the
image for the desktop and for the flake's `wallpapers` output. Because
`base16Scheme` is set explicitly, Stylix never derives colors from the
wallpaper, and the wallpaper can safely depend on the colors.

These are drawn by `generate.py` (numpy, Pillow and pycairo) at 3840x2400, one
image for both 16:10 and 16:9 screens; every design is
centered on the flake, so a 16:9 crop of the top and bottom loses
nothing. Each takes a few seconds to build. They were designed on an
interactive studies board, and `pkgs/wallpapers/styles.nix` holds the seed and
settings picked there. A style plus its seed always draws the same image, and
changing a setting or the seed redraws it.

To tune one, edit `styles.nix` (or `generate.py`) and build it in any scheme,
without touching your theme or evaluating a whole system:

```bash
nix build .#wallpapers.<style>.<system>.<scheme>    # e.g. .#wallpapers.contours.base16.nord
xdg-open result
```

| Style | What it is |
|---|---|
| `layered-ridges` | Hazy mountain ridges, with the flake as a sun half set behind the first range at the center of the screen. |
| `contours` | A topographic map on tinted terraces, rising to the flake on the summit inside a solid cutout. |
| `windlines` | Thousands of fine streamlines combed along the diagonal, with a few glowing currents. |
| `flow-engraving` | Evenly spaced engraved strokes; inside the flake they turn base0D and base04 and get heavier, so the logo shows as hatching. |
| `prism-shards` | Low-poly facets with patches of accent color, and the flake recut from the same mesh as tinted glass. |
| `woven-ribbons` | Waving bands, centered on the logo, that stop short of a raised, shaded flake. |
| `sunburst` | Twisting rays from the flake: base0D and base04 accent rays between dark ones. |

Wherever a style draws the flake it's base0D and base04, backgrounds stay in
base00 to base03, and other accents (base08 to base0E) appear only where a style
asks for them, such as `prism-shards`' `colors`. Some lessons behind that:

- **The accent slots don't form a gradient.** base16 fixes what each accent
  slot is for (red-ish, orange-ish, ...), not its order or brightness.
  base0F especially varies: brown in Eris and Gruvbox, pink in Spaceduck, blue
  in Nord. Assigning five accents to five bands looks random.
- **base00 → base07 is a ramp.** Schemes design the neutrals to step from
  background to foreground, so they make a dependable gradient. Some schemes
  repeat a step (`standardized-dark` has base03 = base04), which flattens
  anything that relies on those two.
- **Low-contrast schemes swallow the dim end.** In `lime`, base02 and base03
  are barely lighter than the background; use base03 or higher for anything
  that should stay visible.

### Adding a wallpaper

In a checkout of this repo:

1. Write a function in `generate.py` and add it to `STYLES`.
2. Add its seed and settings to `styles.nix`.
3. Preview it in any scheme without switching:
   ```bash
   nix build .#wallpapers.<style>.base16.<scheme>
   ```

## Where the colors go

- **Stylix targets.** Most apps are themed by Stylix's own targets: GTK,
  Qt/Kvantum, Firefox, the terminal, Hyprland, Vencord, the login screen, the
  console and the boot splash.
- **Quickshell.** `modules/home/window-managers/hyprland/quickshell/default.nix`
  writes base00–base0F and the fonts into `Theme.qml.json`, which the shell
  reads.
- **Custom configs.** Starship reads `config.lib.stylix.colors` directly.
- **Exceptions.** The desktop profile turns the Qt target on explicitly, because
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
inkscape and bottles, which took minutes. `stylix.nix` therefore sets
`stylix.overlays.enable = false`, for both NixOS and Home Manager. Editor syntax
colors are still themed: the gtksourceview target writes the style to
`~/.local/share/gtksourceview-*/styles/stylix.xml` instead.

If a theme change ever starts compiling large packages again, look for a target
or overlay that changes a package rather than writing a file.
