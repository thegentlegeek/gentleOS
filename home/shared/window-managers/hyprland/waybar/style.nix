{
  config,
  ...
}:
    # Bring in color definitions from stylix
  let 
    stylix00 = config.myColors.stylix00;
    stylix01 = config.myColors.stylix01;
    stylix02 = config.myColors.stylix02;
    stylix03 = config.myColors.stylix03;
    stylix04 = config.myColors.stylix04;
    stylix05 = config.myColors.stylix05;
    stylix06 = config.myColors.stylix06;
    stylix07 = config.myColors.stylix07;
    stylix08 = config.myColors.stylix08;
    stylix09 = config.myColors.stylix09;
    stylix0A = config.myColors.stylix0A;
    stylix0B = config.myColors.stylix0B;
    stylix0C = config.myColors.stylix0C;
    stylix0D = config.myColors.stylix0D;
    stylix0E = config.myColors.stylix0E;
    stylix0F = config.myColors.stylix0F;
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
      background: ${stylix00};
      color: ${stylix07};
      margin-top: 8px;
      margin-left: 16px;
      margin-bottom: 8px;
      border-radius: 10px;
      border: solid;
      border-width: 2px;
      border-color: ${stylix07};
      opacity: 0.9;
    }

    window#waybar {
      background: ${stylix00};
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
      background: ${stylix03};
    }

    #workspaces button {
      transition: none;
      border-radius: 10px;
      color: ${stylix07};
    }

    #workspaces button:active {
      color: ${stylix0A};
      background: ${stylix03};
    }

    #workspaces button:hover {
      transition: none;
      box-shadow: inherit;
      text-shadow: inherit;
      color: ${stylix07};
    }

    #mpris {
      margin-top: 8px;
      padding-left: 16px;
      padding-right: 16px;
      margin-bottom: 8px;
      border-radius: 10px;
      transition: none;
      color: ${stylix07};
      background: ${stylix03};
    }

    #network {
      margin-top: 8px;
      padding-left: 16px;
      padding-right: 16px;
      margin-bottom: 8px;
      border-radius: 10px;
      transition: none;
      color: ${stylix07};
      background: ${stylix03};
    }

    #wireplumber {
      margin-top: 8px;
      padding-left: 16px;
      padding-right: 16px;
      margin-bottom: 8px;
      border-radius: 10px;
      transition: none;
      color: ${stylix07};
      background: ${stylix02};
    }

    #temperature {
      margin-top: 8px;
      padding-left: 16px;
      padding-right: 16px;
      margin-bottom: 8px;
      border-radius: 10px;
      transition: none;
      color: ${stylix00};
      background: ${stylix06};
    }

    #backlight {
      margin-top: 8px;
      padding-left: 16px;
      padding-right: 16px;
      margin-bottom: 8px;
      border-radius: 10px;
      transition: none;
      color: ${stylix00};
      background: ${stylix06};
    }

    #cpu {
      margin-top: 8px;
      padding-left: 16px;
      padding-right: 16px;
      margin-bottom: 8px;
      border-radius: 10px;
      transition: none;
      color: ${stylix07};
      background: ${stylix04};
    }

    #memory {
      margin-top: 8px;
      padding-left: 16px;
      padding-right: 16px;
      margin-bottom: 8px;
      border-radius: 10px;
      transition: none;
      color: ${stylix00};
      background: ${stylix05};
    }

    #clock {
      margin-top: 8px;
      margin-right: 12px;
      padding-left: 16px;
      padding-right: 16px;
      margin-bottom: 8px;
      border-radius: 10px;
      transition: none;
      color: ${stylix07};
      background: ${stylix0D};
    }

    #keyboard-state {
      margin-top: 8px;
      padding-left: 16px;
      padding-right: 16px;
      margin-bottom: 8px;
      border-radius: 10px;
      transition: none;
      color: ${stylix00};
      background: ${stylix05};
    }

    #battery {
      margin-top: 8px;
      padding-left: 16px;
      padding-right: 16px;
      margin-bottom: 8px;
      border-radius: 10px;
      transition: none;
      color: ${stylix07};
      background: ${stylix04};
    }

    #power-profiles-daemon {
      margin-top: 8px;
      padding-left: 16px;
      padding-right: 16px;
      margin-bottom: 8px;
      border-radius: 10px;
      transition: none;
      color: ${stylix07};
      background: ${stylix03};
    }

    #custom-power {
      margin-top: 8px;
      margin-right: 16px;
      padding-left: 16px;
      padding-right: 8px;
      margin-bottom: 8px;
      border-radius: 10px;
      transition: none;
      color: ${stylix00};
      background: ${stylix08};
    }
    '';
}