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
      ../../users/jgeigley.nix                      # Defined users
      ../shared
      ../shared/boot/systemd-boot.nix
      ../shared/cpu/intel.nix                        # Shared Intel CPU config
      ../shared/workstation                          # Shared workstation config
      ../shared/workstation/virtualization.nix       # Enables libvirt
      (import ../shared/workstation/window-managers/hyprland { inherit pkgs lib inputs config; })  # Hyprland configuration shared between hosts
      ../../modules/workstation/stylix.nix
    ];

  # Hardware Enablement
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.hardware.bolt.enable = true;

  # Set network hostname and any other host-specific settings.
  networking.hostName = "lp-23-072";
  boot.kernelPackages = pkgs.linuxKernel.packages.linux_6_12;
  services.fstrim.enable = lib.mkDefault true;

  # System Programs
  environment.systemPackages = with pkgs; [
    bluez
  ];

  # Keep the state version at 23.11
  system.stateVersion = "23.11";
}
