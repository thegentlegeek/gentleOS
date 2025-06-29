{ config, pkgs, ... }:

{
  imports =
    [
      ./sound.nix
      ./network.nix
      ./fonts.nix
      ./keyboard.nix
      ../CLI
    ];

  # Set your time zone.
  time.timeZone = "America/Indiana/Indianapolis";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Enable the X11 windowing system. I think this needs to be enabled
  # even thought I'm using Wayland? It's unclear.
  services.xserver.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable suspend and hibernate states
  powerManagement.enable = true;

  # Enable DBus daemon that allows changing system behavior based on user-selected power profiles
  services.power-profiles-daemon.enable = true;

  # Define power state behavior
  services.logind = {
    powerKey = "poweroff";
    lidSwitchDocked = "ignore";             # Ignore lid closure when an external display is connected
    lidSwitch = "suspend-then-hibernate";   # Suspend the system when no external display is connected
  };

  # System-wide packages
  environment.systemPackages = with pkgs; [
    wget
    curl
    git
    unzip
    unrar
    sshfs
    openssl
    alsa-utils
    mediawriter
    libclang
    nil
    neofetch
    dig
    python3
    usbutils
    wavemon
    kismet
    nfs-utils
  ];

  # Pieces required for OBS Virtual Camera
  boot.extraModulePackages = with config.boot.kernelPackages; [ v4l2loopback ];
  boot.extraModprobeConfig = ''
    options v4l2loopback devices=1 video_nr=1 card_label="OBS Cam" exclusive_caps=1
  '';

  # System
  security.sudo.wheelNeedsPassword = false; #WARNING: This is probably not a good idea but ... I'm lazy sometimes
  security.polkit = {
    enable = true;
  };

  # Automatic garbage collection & nix store optimization
  nix.gc = {
    automatic = true;
    dates = "daily";
    options = "--delete-older-than 7d";
  };
  nix.optimise.automatic = true;
  nix.optimise.dates = [ "04:01" ];

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Enable LVFS firmware updating
  services.fwupd.enable = true;
}
