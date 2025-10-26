{
  inputs,
  config,
  ...
}:

{
  imports =
    [
      ./hardware-configuration.nix
      inputs.home-manager.nixosModules.home-manager
      ../shared
      ../shared/CLI
      ../shared/server/minecraft-server.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Set your time zone.
  time.timeZone = "America/Indiana/Indianapolis";

  # Disable CUPSgit config --global user.email "
  services.printing.enable = false;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.justin = {
    isNormalUser = true;
    home = "/home/justin";
    description = "admin user";
    extraGroups = [ "wheel" "networkmanager" ]; # Add groups as needed
};

  # TEST MOVING THIS TO HOME MANAGER IN FLAKE.NIX
  # List packages installed in system profile
#  environment.systemPackages = with pkgs; [
#    vim
#    wget
#    curl
#    inetutils
#    mtr
#    sysstat
#    mlocate
#    git
#  ];

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = false;

  # Network
  networking = {
    usePredictableInterfaceNames = false;
    useDHCP = false;
    interfaces.eth0.useDHCP = true;
    hostName = "geigcraft-server";
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
  services.logind.lidSwitchExternalPower = "ignore"; # don't sleep or turn off with laptop lid closed
  services.illum.enable = true; # control brightness with brightness keys?

  system.stateVersion = "23.11";

}

