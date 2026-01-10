{ config, pkgs, ... }:

{
  # Enable the KDE Plasma 6 Desktop Environment.
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # Program Enablements
  programs.kdeconnect.enable = true;
  programs.kde-pim = {
    enable = true;  # base packages
    merkuro = true; # calendar
    kontact = true; # contacts
    kmail = true;   # email
  };

  # Individual System Packages
  environment.systemPackages = with pkgs.kdePackages; [
    qtwebengine
    qtwebsockets
    plasma-thunderbolt
    bluedevil
    partitionmanager
    sddm-kcm
  ];
}
