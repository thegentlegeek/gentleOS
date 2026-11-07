# A minimal host on the gentleOS desktop, used by the checks in checks/.
{
  ...
}:

{
  imports =
    [
      ../../users/demo/system.nix
      ../../modules/nixos/profiles/desktop.nix
    ];

  networking.hostName = "demo";
  time.timeZone = "UTC";

  # Placeholders for a real machine's hardware-configuration.nix.
  boot.loader.systemd-boot.enable = true;
  fileSystems."/" = { device = "/dev/disk/by-label/nixos"; fsType = "ext4"; };
  nixpkgs.hostPlatform = "x86_64-linux";

  system.stateVersion = "26.05";
}
