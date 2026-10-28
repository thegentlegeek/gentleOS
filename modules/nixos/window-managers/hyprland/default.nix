{
  pkgs,
  lib,
  inputs,
  ...
}:
let
  hyprlandPkgs = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system};
in

{
  imports =
    [
      ../../workstation/regreet.nix
    ];

  # Enable Hyprland
  programs.hyprland = {
    enable = true;
    withUWSM = true;
    # Upstream release flake (pinned in flake.nix). The portal must match the compositor.
    package = hyprlandPkgs.hyprland;
    portalPackage = hyprlandPkgs.xdg-desktop-portal-hyprland;
  };

  # Mesa intentionally stays on our nixpkgs. Overriding it with the Mesa from
  # Hyprland's nixpkgs (unstable) breaks every GL app built from our stable
  # nixpkgs: cage/ReGreet failed EGL init ("EGL_EXT_platform_base not
  # supported") and the greeter crash-looped. Hyprland itself runs fine on the
  # stable driver (verified nested: EGL/GBM init OK on Mesa 26.1.8).
  
  programs.thunar = {
    enable = true;
    plugins = with pkgs; [
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
    kdePackages.kiconthemes
    kdePackages.breeze-icons
    spicetify-cli      # cli tool to theme spotify. Used by stylix to theme it
  ];
}