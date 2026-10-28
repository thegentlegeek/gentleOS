{
  pkgs,
  lib,
  ...
}: 

{
  imports =
    [
      ../../workstation/regreet.nix
    ];

  # Enable Hyprland
  programs.hyprland = {
    enable = true;
    withUWSM = true;
  };
  
  programs.waybar.enable = true;
  programs.thunar = {
    enable = true;
    plugins = with pkgs.xfce; 
      [ 
      thunar-archive-plugin 
      thunar-volman
      ];
  };

  programs.ssh.askPassword = "${pkgs.lxqt.lxqt-openssh-askpass}/bin/lxqt-openssh-askpass";
  services.gvfs.enable = true;      # virtual filesystem support for Thunar to manage mounts etc.
  security.pam.services.hyprlock = {};    # required for hyprlock to use PAM for authentication

  
  # A quiet variant of the uwsm Hyprland session that keeps startup
  # messages off the text VT (greetd runs .desktop Exec without a shell,
  # hence the wrapper script).
  # Individual System Packages
  environment.systemPackages = with pkgs; [
    (writeTextDir "share/wayland-sessions/hyprland-quiet.desktop" (lib.generators.toINI { } {
      "Desktop Entry" = {
        Name = "Hyprland (quiet)";
        Comment = "Hyprland (uwsm-managed), startup output silenced";
        Exec = lib.getExe (writeShellScriptBin "hyprland-quiet" ''
          exec ${lib.getExe pkgs.uwsm} start -e -D Hyprland hyprland.desktop >/dev/null 2>&1
        '');
        Type = "Application";
        DesktopNames = "Hyprland";
      };
    }))

    # Apps
    kitty         # terminal
    kdePackages.ark
    gnome-boxes
    gnome-calculator

    # System
    blueman       # bluetooth manager GUI gtk
    brightnessctl # screen brightness control
    hyprls        # LSP server for Hyprland config language
    egl-wayland
    kdePackages.qtwayland
    kdePackages.qtbase
    #lxqt.lxqt-openssh-askpass

    # Dependencies
    parallel                        # parallel processing
    jq                              # json processing
    imagemagick                     # image processing

    # Hypr
    hyprshot          # screenshot tool
    hyprpicker        # color picker
    slurp             # region select for screenshot/screenshare
    swappy            # screenshot editor
    cliphist          # clipboard manager
    hyprcursor        # cursor format, library, utilities
    wl-clipboard      # clipboard utilities, used by cliphist watch and hyprshot

    # Theming
    kdePackages.qt6ct
    kdePackages.qtstyleplugin-kvantum
    kdePackages.kiconthemes
    kdePackages.breeze-icons
    spicetify-cli      # cli tool to theme spotify. Used by stylix to theme it
  ];
}