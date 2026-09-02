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
      ../../users/justin/system.nix                  # User system configuration
      ../../modules/nixos/base.nix
      ../../modules/nixos/boot/systemd-boot.nix
      ../../modules/nixos/cpu/amd.nix               # Shared AMD CPU config
      ../../modules/nixos/workstation                # Shared workstation config
      ../../modules/nixos/workstation/virtualization.nix  # Enables libvirt
      (import ../../modules/nixos/window-managers/hyprland { inherit pkgs lib inputs config; })
      ../../modules/shared/stylix.nix
    ];

  # Hardware Enablement
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.hardware.bolt.enable = true;

  # Set network hostname and any other host-specific settings.
  networking.hostName = "zbook";
  # linux_6_12's Display Core (v3.2.301) predates a lot of amdgpu/DCN 3.1.x
  # fixes relative to the userspace (Mesa) we run. Pin was inherited from
  # the previous Intel laptop; use latest for this AMD box.
  boot.kernelPackages = pkgs.linuxPackages_latest;
  services.fstrim.enable = lib.mkDefault true;

  # System Programs
  environment.systemPackages = with pkgs; [
    bluez
  ];

  # Keep the state version at 23.11
  system.stateVersion = "23.11";
}
