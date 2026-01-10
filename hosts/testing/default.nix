{
  pkgs,
  lib,
  inputs,
  config,
  ...
}:

{
  imports =
    [
      inputs.home-manager.nixosModules.home-manager
      ./hardware-configuration.nix                   # Host-specific hardware settings
      ../../users/jgeigley/system.nix                # User system configuration
      ../../modules/nixos/base.nix
      ../../modules/nixos/cpu/intel.nix              # Shared Intel CPU config
      ../../modules/nixos/workstation                # Shared workstation config
      ../../modules/nixos/workstation/virtualization.nix  # Enables libvirt
      (import ../../modules/nixos/window-managers/hyprland { inherit pkgs lib inputs config; })
      ../../modules/shared/stylix.nix
    ];

  # Enable Flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Boot stuff
  boot.loader.grub = {
    enable = true;
    device= "nodev";
    #gfxmodeBios = "1280x720";
    #gfxmodeEfi = "1280x720";
    efiSupport = true;
    useOSProber = true;
  };

  boot.loader.efi.canTouchEfiVariables = true;
  boot.supportedFilesystems = [ "ntfs" ];
  boot.plymouth.enable = true;

  # Hardware Enablement
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.hardware.bolt.enable = true;

  # Set network hostname and any other host-specific settings.
  networking.hostName = "testing";
  #networking.interfaces.enp0s31f6.wakeOnLan.enable = true; # Built-in ethernet port

  # System Programs
  environment.systemPackages = with pkgs; [
    bluez
  ];

  # SSD Trim
  services.fstrim.enable = lib.mkDefault true;

  # Keep the state version at 23.11
  system.stateVersion = "23.11";
}
