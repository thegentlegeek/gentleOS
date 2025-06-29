{ pkgs, ... }:

{
  home.stateVersion = "24.05";  # Set Home Manager state version
  home.directory = "/home/justin";  # Can be customized per host
  home.description = "Justin Geigley";

  # SSH keys configuration
  programs.ssh = {
    enable = true;
    authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKzQ06Tt+VS2dL0uEsxftmVXF6hjSzx3fYl4H27V29rf justin@gentlegeeks.com"
    ];
  };

  # Additional packages for Justin
  home.packages = with pkgs; [

  ];
}
