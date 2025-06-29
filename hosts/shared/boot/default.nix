{
  ...
}:

{
  imports =
    [
      # Only pick one ...
      #./grub.nix
      ./systemd-boot.nix
    ];

  boot.loader.efi.canTouchEfiVariables = true;
  boot.supportedFilesystems = [ "ntfs" ];
  boot.plymouth.enable = true;

  # Keep the state version at 23.11
  system.stateVersion = "23.11";
}
