{
  pkgs,
  ...
}: 

{
  imports =
    [
      ../../sddm.nix
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
  security.soteria.enable = true;   # GTK polkit agent, haven't figured out how to use this yet
  security.pam.services.hyprlock = {};    # required for hyprlock to use PAM for authentication

  
  # Individual System Packages
  environment.systemPackages = with pkgs; [
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
    grimblast         # screenshot tool
    hyprpicker        # color picker
    slurp             # region select for screenshot/screenshare
    swappy            # screenshot editor
    cliphist          # clipboard manager
    hyprcursor        # cursor format, library, utilities

    # Theming
    kdePackages.qt6ct
    kdePackages.qtstyleplugin-kvantum
    kdePackages.kiconthemes
    kdePackages.breeze-icons
    spicetify-cli      # cli tool to theme spotify. Used by stylix to theme it
  ];
}