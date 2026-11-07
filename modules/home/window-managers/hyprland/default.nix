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

  options.gentleOS = {
    # SUPER+B, SUPER+SHIFT+B and the launcher's web search. Without a browser
    # those binds don't exist and web search uses xdg-open.
    browser = {
      personal = lib.mkOption {
        type = lib.types.nullOr (lib.types.listOf lib.types.str);
        default = null;
        example = [ "firefox" ];
        description = "argv of your browser.";
      };
      work = lib.mkOption {
        type = lib.types.nullOr (lib.types.listOf lib.types.str);
        default = null;
        example = [ "chromium" "--profile-directory=Profile 3" ];
        description = "argv of a second browser or profile.";
      };
    };

    # Apps the desktop doesn't install. Unset, their binds don't exist, rather
    # than doing nothing when pressed.
    apps = {
      editor = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "codium";
        description = "Command for SUPER+E.";
      };
      music = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "spotify";
        description = "Command for SUPER+M.";
      };
      terminal = lib.mkOption {
        type = lib.types.str;
        default = "${lib.getExe pkgs.kitty} fish";
        defaultText = lib.literalExpression ''"''${lib.getExe pkgs.kitty} fish"'';
        example = "foot";
        description = "Command for SUPER+C. The launcher still opens terminal apps in kitty.";
      };
      fileManager = lib.mkOption {
        type = lib.types.str;
        default = "${lib.getExe pkgs.kitty} yazi";
        defaultText = lib.literalExpression ''"''${lib.getExe pkgs.kitty} yazi"'';
        example = "thunar";
        description = "Command for SUPER+F.";
      };
    };

    binds = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule {
        options = {
          keys = lib.mkOption {
            type = lib.types.str;
            example = "SUPER + G";
            description = "Keys, spelled as in the cheat sheet (SUPER + /). A bind on the same keys is replaced.";
          };
          command = lib.mkOption {
            type = lib.types.str;
            example = "gimp";
            description = "Command to run.";
          };
          description = lib.mkOption {
            type = lib.types.str;
            example = "Apps: GIMP";
            description = "Cheat sheet entry, as \"Category: text\".";
          };
        };
      });
      default = [ ];
      description = "Your own key binds. For anything but running a command, use hl.bind in wayland.windowManager.hyprland.extraConfig.";
    };

    autostart = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "discord --start-minimized" ];
      description = "Commands to run once at login, each in its own systemd scope.";
    };

    clock24Hour = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Show the bar's clock in 24-hour time.";
    };

    # Its own option, not stylix.fonts: the bar and panels mix text with Nerd Font
    # icons, which a terminal font may well not have.
    shellFont = {
      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.nerd-fonts.jetbrains-mono;
        defaultText = lib.literalExpression "pkgs.nerd-fonts.jetbrains-mono";
        description = "Package with the bar and panels' font.";
      };
      name = lib.mkOption {
        type = lib.types.str;
        default = "JetBrainsMono Nerd Font Propo";
        description = "Font family of the bar and panels, and in `shellFont.package`, or the build fails. Without Nerd Font glyphs, the icons show as boxes. Of a Nerd Font's variants, Propo keeps icons at their natural size.";
      };
    };

    monitors = lib.mkOption {
      type = lib.types.attrsOf (lib.types.listOf (lib.types.submodule {
        options = {
          output = lib.mkOption { type = lib.types.str; description = "Output name, as in `hyprctl monitors`."; };
          mode = lib.mkOption { type = lib.types.str; default = "preferred"; };
          position = lib.mkOption { type = lib.types.str; default = "auto"; };
          scale = lib.mkOption { type = lib.types.nullOr lib.types.number; default = null; description = "Null lets Hyprland choose."; };
        };
      }));
      default = { };
      example = lib.literalExpression ''{ laptop = [ { output = "eDP-1"; scale = 1.5; } ]; }'';
      description = "Monitor layouts by hostname. Outputs not listed use preferred mode, auto position and `monitorScale`.";
    };

    monitorScale = lib.mkOption {
      type = lib.types.nullOr lib.types.number;
      default = null;
      description = "Scale of monitors not listed in `monitors`. Null lets Hyprland choose.";
    };

    keyboardLayout = lib.mkOption {
      type = lib.types.str;
      default = "us";
      description = "XKB layout on the desktop. The console and greeter are set on the NixOS side.";
    };

    keyboardVariant = lib.mkOption {
      type = lib.types.str;
      default = "";
      example = "dvorak";
      description = "XKB variant on the desktop.";
    };

    keyboardOptions = lib.mkOption {
      type = lib.types.str;
      default = "";
      example = "caps:escape";
      description = "XKB options on the desktop, separated by commas.";
    };

    idleDimSeconds = lib.mkOption {
      type = lib.types.nullOr lib.types.ints.positive;
      default = 150;
      description = "Idle time before the screen dims. Null never dims.";
    };

    idleLockSeconds = lib.mkOption {
      type = lib.types.nullOr lib.types.ints.positive;
      default = 300;
      description = "Idle time before the screen locks. Null never locks when idle, though it still locks before sleeping.";
    };

    idleScreenOffSeconds = lib.mkOption {
      type = lib.types.nullOr lib.types.ints.positive;
      default = 330;
      description = "Idle time before the screen turns off. Null leaves it on.";
    };

    idleSuspendSeconds = lib.mkOption {
      type = lib.types.nullOr lib.types.ints.positive;
      default = 1800;
      description = "Idle time before the machine sleeps. Null never sleeps when idle, such as on a desktop.";
    };

    searchUrl = lib.mkOption {
      type = lib.types.str;
      default = "https://www.google.com/search?q=%s";
      description = "The launcher's web search. %s is the URL-encoded query.";
    };

    flakePath = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/nix-config";
      description = "Checkout of the flake that holds your hosts and theme file, for the theme picker. It's built as homeConfigurations.$USER and nixosConfigurations.<hostname>, and must expose gentleOS's legacyPackages. GENTLEOS_FLAKE overrides it.";
    };
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
