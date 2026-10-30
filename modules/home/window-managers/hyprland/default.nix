{
  config,
  lib,
  pkgs,
  ...
}:


{
  imports =
    [
      ./hyprland-config.nix
      ./quickshell
      ./hypridle.nix
    ];

  # Browser profiles, used by the SUPER+B binds and the launcher's web search.
  options.gentleOS.browser = lib.mkOption {
    type = lib.types.attrsOf (lib.types.listOf lib.types.str);
    default = {
      personal = [ "chromium" "--profile-directory=Profile 2" ];
      work = [ "chromium" "--profile-directory=Profile 3" ];
    };
    description = "argv of the browser for each profile (personal, work).";
  };

  # Icon theme caches, like NixOS's gtk.iconCache for the system profile
  # (modules/nixos/window-managers/hyprland). Without one, every first lookup
  # of an icon by name searches the theme directory by directory.
  config = {
    # The home-manager profile: several packages add to hicolor here, so no
    # package's own cache covers it. A theme only one package provides is a
    # symlink into the store; it's replaced by a directory of links unless
    # that package ships a cache.
    home.extraProfileCommands = ''
      if [ -d "$out/share/icons" ]; then
        find "$out/share/icons" -mindepth 1 -maxdepth 1 -print0 | while read -r -d $'\0' themedir; do
          [ -d "$themedir" ] || continue
          if [ -L "$themedir" ] && [ ! -r "$themedir/icon-theme.cache" ]; then
            path=$(readlink -f "$themedir")
            rm "$themedir"
            mkdir "$themedir"
            ln -s "$path"/* "$themedir"/
          fi
          if [ ! -L "$themedir" ] && [ -w "$themedir" ]; then
            rm -f "$themedir/icon-theme.cache"
            ${pkgs.buildPackages.gtk3.out}/bin/gtk-update-icon-cache --ignore-theme-index "$themedir"
          fi
        done
      fi
    '';

    # ~/.local/share/icons/hicolor, where Steam puts game icons. Rebuilt on
    # each switch; icons added in between make it older than the directory,
    # and GTK and Qt then ignore it and search as before.
    home.activation.userIconCache = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ -d "${config.xdg.dataHome}/icons/hicolor" ]; then
        run ${pkgs.gtk3.out}/bin/gtk-update-icon-cache --quiet --force --ignore-theme-index "${config.xdg.dataHome}/icons/hicolor"
      fi
    '';
  };
}
