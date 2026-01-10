{
  config,
  ...
}:
    # Bring in color definitions from stylix
  let 
    colors = config.lib.stylix.colors.withHashtag;
  in
{

  # Define CSS 
  programs.waybar.style =
    ''
    * {
      border: none;
      border-radius: 0;
      font-family: JetBrainsMono Nerd Font Mono;
      font-size: 15px;
      min-height: 24px;
    }

    tooltip {
      background: ${colors.base00};
      color: ${colors.base07};
      margin-top: 8px;
      margin-left: 16px;
      margin-bottom: 8px;
      border-radius: 10px;
      border: solid;
      border-width: 2px;
      border-color: ${colors.base07};
      opacity: 0.9;
    }

    window#waybar {
      background: ${colors.base00};
      border-radius: 0px;
      margin-top: 16px;
      margin-right: 16px;
      margin-left: 16px;
      padding-top: 8px;
      padding-left: 8px;
      padding-right: 8px;
      opacity: 0.8;
    }

    #workspaces {
      transition: none;
      margin-top: 8px;
      margin-left: 16px;
      margin-bottom: 8px;
      border-radius: 10px;
      background: ${colors.base03};
    }

    #workspaces button {
      transition: none;
      border-radius: 10px;
      color: ${colors.base07};
    }

    #workspaces button:active {
      color: ${colors.base0A};
      background: ${colors.base03};
    }

    #workspaces button:hover {
      transition: none;
      box-shadow: inherit;
      text-shadow: inherit;
      color: ${colors.base07};
    }

    #mpris {
      margin-top: 8px;
      padding-left: 16px;
      padding-right: 16px;
      margin-bottom: 8px;
      border-radius: 10px;
      transition: none;
      color: ${colors.base07};
      background: ${colors.base03};
    }

    #network {
      margin-top: 8px;
      padding-left: 16px;
      padding-right: 16px;
      margin-bottom: 8px;
      border-radius: 10px;
      transition: none;
      color: ${colors.base07};
      background: ${colors.base03};
    }

    #wireplumber {
      margin-top: 8px;
      padding-left: 16px;
      padding-right: 16px;
      margin-bottom: 8px;
      border-radius: 10px;
      transition: none;
      color: ${colors.base07};
      background: ${colors.base02};
    }

    #temperature {
      margin-top: 8px;
      padding-left: 16px;
      padding-right: 16px;
      margin-bottom: 8px;
      border-radius: 10px;
      transition: none;
      color: ${colors.base00};
      background: ${colors.base06};
    }

    #backlight {
      margin-top: 8px;
      padding-left: 16px;
      padding-right: 16px;
      margin-bottom: 8px;
      border-radius: 10px;
      transition: none;
      color: ${colors.base00};
      background: ${colors.base06};
    }

    #cpu {
      margin-top: 8px;
      padding-left: 16px;
      padding-right: 16px;
      margin-bottom: 8px;
      border-radius: 10px;
      transition: none;
      color: ${colors.base07};
      background: ${colors.base04};
    }

    #memory {
      margin-top: 8px;
      padding-left: 16px;
      padding-right: 16px;
      margin-bottom: 8px;
      border-radius: 10px;
      transition: none;
      color: ${colors.base00};
      background: ${colors.base05};
    }

    #clock {
      margin-top: 8px;
      margin-right: 12px;
      padding-left: 16px;
      padding-right: 16px;
      margin-bottom: 8px;
      border-radius: 10px;
      transition: none;
      color: ${colors.base07};
      background: ${colors.base0D};
    }

    #keyboard-state {
      margin-top: 8px;
      padding-left: 16px;
      padding-right: 16px;
      margin-bottom: 8px;
      border-radius: 10px;
      transition: none;
      color: ${colors.base00};
      background: ${colors.base05};
    }

    #battery {
      margin-top: 8px;
      padding-left: 16px;
      padding-right: 16px;
      margin-bottom: 8px;
      border-radius: 10px;
      transition: none;
      color: ${colors.base07};
      background: ${colors.base04};
    }

    #power-profiles-daemon {
      margin-top: 8px;
      padding-left: 16px;
      padding-right: 16px;
      margin-bottom: 8px;
      border-radius: 10px;
      transition: none;
      color: ${colors.base07};
      background: ${colors.base03};
    }

    #custom-power {
      margin-top: 8px;
      margin-right: 16px;
      padding-left: 16px;
      padding-right: 8px;
      margin-bottom: 8px;
      border-radius: 10px;
      transition: none;
      color: ${colors.base00};
      background: ${colors.base08};
    }
    '';
}