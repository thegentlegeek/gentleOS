{
  lib,
  ...
}:

{
  # Enable networking
  networking.networkmanager = {
    enable = true;
    wifi.macAddress = lib.mkDefault "permanent";
    wifi.powersave = lib.mkDefault true;
  };

  # Firewall
  networking.firewall.enable = lib.mkDefault true;
}
