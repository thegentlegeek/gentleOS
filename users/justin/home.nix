{
  pkgs,
  inputs,
  stylix,
  ...
}:

{
  imports = [
    ../../modules/shared/stylix.nix
    ../../modules/home/cli
    ../../modules/home/window-managers/hyprland
    ../../modules/home/editors/vscode.nix
    ../../modules/home/editors/zed.nix
    (import ../../modules/home/editors/opencode.nix {
      opencodePackage = inputs.llm-agents.packages.x86_64-linux.opencode;
    })
    ../../modules/home/browsers/chromium.nix
    stylix.homeModules.stylix
  ];

  ## User specific stylix options. 
  # Main config in stylix module that is imported to Home Manager and NixOS system config
  stylix = {
    targets.waybar.enable = false;
    targets.rofi.enable = false;
    targets.dunst.enable = false;
    targets.firefox.profileNames = [ "default" ];
  };

  home = {
    #backupFileExtension = "backup";
    stateVersion = "25.05";  # Set Home Manager state version
    username = "justin";
    homeDirectory = "/home/justin";  # Home directory for Justin Geigley
    
    # User specific packages that aren't declarative (yet?) I think?
    packages = with pkgs; [
      vlc
      pavucontrol
      remmina
      bitwarden-desktop
      qbittorrent-enhanced
      moonlight-qt
      calibre
      bottles
      inkscape
      gimp-with-plugins
      yai # CLI tool that uses API to talk with ChatGPT
      aichat
      zoom-us
      dbeaver-bin
      libreoffice
      discord
      chessx
      sshs   # cool CLI ssh interface. Use it again if you've forgotten about it future me. - Love, past you
    ];

    # Wayland session variables for Electron apps
    sessionVariables = {
      NIXOS_OZONE_WL = "1";
    };
  };

  programs = {
    home-manager.enable = true;
    hyprlock.enable = true;
    git.settings = {
      enable = true;
      user.email = "justin@geigley.com";
      user.name = "thegentlegeek";
    };
    freetube.enable = true;
    spotify-player.enable = true;
    firefox.enable = true;
  };
}
