{ config, pkgs, ... }:
{

  imports =
    [

    ];

  users.users.justin = {
    isNormalUser = true;
    description = "Justin";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
      ungoogled-chromium
      firefox
      nextcloud-client
      bitwarden
      bitwarden-cli
      sshfs # for KDE Connect to remote view phone storage
      mediawriter
      freetube
    ];
  };

}
