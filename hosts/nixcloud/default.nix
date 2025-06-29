{
  config,
  pkgs,
  ...
}:

{
  imports =
    [
      ./hardware-configuration.nix
      ../shared
      ../shared/server/gitea.nix
    ];

  # Use the GRUB 2 boot loader.
  boot.loader.grub.enable = true;

  # Set your time zone.
  time.timeZone = "America/Indiana/Indianapolis";

  # Disable CUPS
  services.printing.enable = false;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.justin = {
    isNormalUser = true;
    home = "/home/gentlegeek";
    description = "admin user";
    extraGroups = [ "wheel" "networkmanager" "gitea" ]; # Add groups as needed
};

  # List packages installed in system profile
  environment.systemPackages = with pkgs; [
    wget
    curl
    inetutils
    mtr
    sysstat
    mlocate
    git
  ];

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = false;

  # Network
  networking = {
    usePredictableInterfaceNames = false;
    useDHCP = false;
    interfaces.eth0.useDHCP = true;
    hostName = "nixcloud";
    networkmanager.enable = true;
  };

  # Software Services
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "both";
  };


  # Firewall
  networking.firewall = {
      enable = true;
      trustedInterfaces = ["tailscale0"];
      allowedUDPPorts = [
        config.services.tailscale.port
      ];
      allowedTCPPorts = [
	config.services.tailscale.port
      ];
  };

  # System
  security.sudo.wheelNeedsPassword = false;


  system.stateVersion = "23.11";

}

