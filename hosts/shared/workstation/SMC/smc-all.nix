{ config, pkgs, ... }:

{
  imports =
    [
      ./smc-network.nix
    ];


  environment.systemPackages = with pkgs; [
  remmina
	dbeaver-bin
	zoom-us
	apache-directory-studio
  ];
}
