# A placeholder. Replace it with your machine's:
#   sudo nixos-generate-config --show-hardware-config > hardware-configuration.nix
{
  fileSystems."/" = { device = "/dev/disk/by-label/nixos"; fsType = "ext4"; };
  nixpkgs.hostPlatform = "x86_64-linux";
}
