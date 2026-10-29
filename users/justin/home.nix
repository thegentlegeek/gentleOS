{
  pkgs,
  config,
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
      opencodePackage = inputs.llm-agents.packages.x86_64-linux.opencode2;
      opencodeDesktopPackage = inputs.llm-agents.packages.x86_64-linux.opencode2-desktop;
    })
    (import ../../modules/home/editors/claude.nix {
      claudeCodePackage = inputs.llm-agents.packages.x86_64-linux.claude-code;
      claudeDesktopPackage = inputs.llm-agents.packages.x86_64-linux.claude-desktop;
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
    # Stylix overlays patch gtksourceview (and nixos-icons) with the scheme, which
    # forces local source builds of everything depending on it (inkscape, bottles)
    # on every theme change. The gtksourceview target still themes via ~/.local/share.
    overlays.enable = false;
    targets.opencode.enable = false; # Stylix generates OpenCode 1 themes; v2 uses the "system" theme instead
    # Qt via qtct + generated Kvantum theme. Not auto-enabled for standalone HM
    # (home-manager#6565 only affects non-NixOS hosts); matches the NixOS target's qt5ct.
    targets.qt.enable = true;
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
    firefox = {
      enable = true;
      configPath = "${config.xdg.configHome}/mozilla/firefox";
    };
  };
}
