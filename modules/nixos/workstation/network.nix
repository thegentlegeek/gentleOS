{
  config,
  ...
}:

{
  # Enable networking
  networking.networkmanager = {
    enable = true;
    wifi.macAddress = "permanent";
    wifi.powersave = true;
  };

  # Tailscale
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "client";
  };

  # Firewall
  networking.firewall = {
      enable = true;
      trustedInterfaces = ["tailscale0"];
      allowedUDPPorts = [
      config.services.tailscale.port
      ];
      allowedTCPPorts = [
      ];
  };
}
