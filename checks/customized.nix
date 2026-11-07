# Every documented way to change the desktop, set as someone's own flake would:
# at normal priority, with no lib.mkForce. checks/default.nix keeps these working.
{
  # For both sides, as the README's style.nix.
  style = { lib, pkgs, ... }: {
    stylix = {
      fonts = {
        monospace = {
          package = pkgs.nerd-fonts.fira-code;
          name = "FiraCode Nerd Font Mono";
        };
        sizes.desktop = 14;
      };
      cursor.size = 32;
      opacity.terminal = 1.0;
    };
    gentleOS.theme.image = pkgs.runCommandLocal "wallpaper.png" { nativeBuildInputs = [ pkgs.imagemagick ]; } ''
      magick -size 1920x1080 gradient:navy-black $out
    '';
  };

  home = { lib, pkgs, ... }: {
    gentleOS = {
      # Not on the system side, so this also checks fontconfig finds Home Manager's fonts.
      shellFont = {
        package = pkgs.nerd-fonts.hack;
        name = "Hack Nerd Font Propo";
      };
      binds = [
        { keys = "SUPER + G"; command = "touch $HOME/new-bind"; description = "Apps: Mine"; }
        # In use by default: Screenshots: Region to clipboard.
        { keys = "SUPER + T"; command = "touch $HOME/rebound"; description = "Tools: Rebound"; }
      ];
      autostart = [ "sh -c 'touch $HOME/autostarted; exec sleep 600'" ];
      clock24Hour = true;
      keyboardVariant = "intl"; # Leaves the keys the VM test presses where they are.
      keyboardOptions = "caps:escape";
      idleDimSeconds = null;
      idleLockSeconds = 900;
      idleScreenOffSeconds = 1000;
      apps = {
        terminal = ''${lib.getExe pkgs.kitty} sh -c "touch $HOME/custom-terminal; exec sleep 600"'';
        fileManager = ''${lib.getExe pkgs.kitty} sh -c "touch $HOME/custom-files; exec sleep 600"'';
      };
    };

    programs.kitty.settings.tab_bar_edge = "bottom";
    programs.starship.settings.time.time_format = "%T";
    programs.gh.settings.git_protocol = "ssh";

    # The README's examples of changing Hyprland's own settings.
    wayland.windowManager.hyprland.extraConfig = lib.mkAfter ''
      hl.config({
        general = { gaps_out = 20 },
        decoration = { rounding = 3, active_opacity = 1.0, inactive_opacity = 1.0 },
        input = { touchpad = { natural_scroll = false } },
      })
      hl.window_rule({ name = "float-vlc", match = { class = "^(vlc)$" }, float = true })
    '';
  };

  system = {
    programs.tmux.keyMode = "emacs";
    programs.neovim.defaultEditor = false;
    programs.thunar.enable = false;
    services.pipewire.jack.enable = false;
    environment.shellAliases.ll = "ls -l";
  };
}
