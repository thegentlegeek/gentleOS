{
  pkgs,
  stylix,
  ...
}:


{
  imports =
    [
      ../../../modules/workstation
      ../../shared/CLI
      ../../shared/window-managers/hyprland
      stylix.homeManagerModules.stylix
      ../../../modules/workstation/stylix.nix
    ];

  ## User specific stylix options. 
  # Main config in stylix module that is imported to Home Manager and NixOS system config
  stylix = {
    targets.waybar.enable = false;
    targets.rofi.enable = false;
    targets.dunst.enable = false;
  };

  home = {
    #backupFileExtension = "backup";
    stateVersion = "25.05";  # Set Home Manager state version
    username= "justin";
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
      en-croissant
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
    vscode = {
      enable = true;
      package = pkgs.vscodium;
      mutableExtensionsDir = false;
      profiles.default = {
        enableUpdateCheck = false;
      	enableExtensionUpdateCheck = false;
      	extensions = with pkgs.vscode-extensions;
          [
            jnoortheen.nix-ide
            gruntfuggly.todo-tree
          ];
        userSettings = {            
          "git.confirmSync" = false;
          "git.enableSmartCommit" = true;
        
          "editor.inlineSuggest.enabled" = true;
        
          "[nix]"."editor.defaultFormatter" = "jnoortheen.nix-ide";
        
          "nix.enableLanguageServer" = true;
          "nix.formatterPath" = "${pkgs.alejandra}/bin/alejandra";
          "nix.serverPath" = "${pkgs.nil}/bin/nil";
          "nix.serverSettings"."nil"."formatting"."command" = ["${pkgs.alejandra}/bin/alejandra"];
        };
      };
    };
    chromium = {
      enable = true;
      extensions = [
        "nngceckbapebfimnlniiiahkandclblb" # Bitwarden
        "mpdajninpobndbfcldcmbpnnbhibjmch" # SAML-Tracer
        ];
    };
    hyprlock = {
      enable = true;
    };
    git = {
      enable = true;
      userEmail = "justin@geigley.com";
      userName = "thegentlegeek";
    };
    freetube.enable = true;
    spotify-player.enable = true;
    firefox.enable = true;
      };
}
