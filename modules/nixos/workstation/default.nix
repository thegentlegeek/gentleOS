{ config, lib, pkgs, ... }:

{
  imports =
    [
      ./sound.nix
      ./network.nix
      ./fonts.nix
      ../cli
    ];

  # Opinions below are defaults, so a host can set its own without lib.mkForce.
  # There's no default time zone: set time.timeZone in your host.

  # Select internationalisation properties.
  i18n.defaultLocale = lib.mkDefault "en_US.UTF-8";

  i18n.extraLocaleSettings = lib.genAttrs [
    "LC_ADDRESS"
    "LC_IDENTIFICATION"
    "LC_MEASUREMENT"
    "LC_MONETARY"
    "LC_NAME"
    "LC_NUMERIC"
    "LC_PAPER"
    "LC_TELEPHONE"
    "LC_TIME"
  ] (_: lib.mkDefault config.i18n.defaultLocale);

  # Enable CUPS to print documents.
  services.printing.enable = lib.mkDefault true;

  # Enable suspend and hibernate states
  powerManagement.enable = lib.mkDefault true;

  # Enable DBus daemon that allows changing system behavior based on user-selected power profiles
  services.power-profiles-daemon.enable = lib.mkDefault true;

  # Battery state over D-Bus, for the Quickshell bar's battery module.
  services.upower.enable = true;

  # Define power state behavior
  services.logind.settings.Login = {
    HandlePowerKey = lib.mkDefault "poweroff";
    HandleLidSwitchDocked = lib.mkDefault "ignore";             # Ignore lid closure when an external display is connected
    # Suspend the system when no external display is connected. Hibernating needs swap.
    HandleLidSwitch = lib.mkDefault (if config.swapDevices != [ ] then "suspend-then-hibernate" else "suspend");
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
    dig
    python3
    usbutils
    nfs-utils
  ];

  # System
  security.polkit = {
    enable = true;
  };

  # Automatic garbage collection & nix store optimization
  nix.gc = {
    automatic = lib.mkDefault true;
    dates = lib.mkDefault "daily";
    options = lib.mkDefault "--delete-older-than 7d";
  };
  nix.optimise.automatic = lib.mkDefault true;
  nix.optimise.dates = lib.mkDefault [ "04:01" ];

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Enable LVFS firmware updating
  services.fwupd.enable = lib.mkDefault true;
}
