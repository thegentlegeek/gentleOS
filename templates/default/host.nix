{ hostname, username, ... }:

{
  networking.hostName = hostname;
  time.timeZone = "UTC"; # for example "America/New_York"

  # For a UEFI machine. A BIOS one needs boot.loader.grub instead.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  users.users.${username} = {
    isNormalUser = true;
    extraGroups = [ "networkmanager" "wheel" ];
  };

  gentleOS.themeFile = ./theme.json;

  # Copy this from /etc/nixos/configuration.nix, then leave it alone.
  system.stateVersion = "26.05";
}
